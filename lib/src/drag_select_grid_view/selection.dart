import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../misc/utils.dart';

/// Holds and calculates selected indexes based on gestures.
///
/// This class is conceptually tied to UI gestures, so its methods have names
/// that suggest interactions (specifically tap and drag), however it just holds
/// data and makes some calculations.
///
/// This behavior is unusual, but in this situation it helps to keep everything
/// more didactic, since you can easily link the UI action to it's consequence
/// regarding selection.
class SelectionManager {
  bool _selectPositive = true;

  /// The index in which the drag started.
  int get dragStartIndex => _dragStartIndex;
  var _dragStartIndex = -1;

  /// The last known index which was dragged by.
  int get dragEndIndex => _dragEndIndex;
  var _dragEndIndex = -1;

  /// Gets the indexes that are currently selected.
  ///
  /// Indexes can be directly selected, with [_selectedIndexes] setter, and
  /// selected by gestures, with [startDrag], [updateDrag], [endDrag] and [tap].
  Set<int> get selectedIndexes => UnmodifiableSetView(_selectedIndexes);
  Set<int> temporaryIndexes = {};

  /// Sets the indexes that are currently selected.
  ///
  /// Any drag that is currently active will be interrupted.
  set selectedIndexes(Set<int> selectedIndexes) {
    endDrag();
    _selectedIndexes = Set.of(selectedIndexes);
  }

  var _selectedIndexes = <int>{};

  /// Removes all indexes from [_selectedIndexes].
  ///
  /// Any drag that is currently active will be interrupted.
  void clear() {
    endDrag();
    _selectedIndexes.clear();
  }

  /// Adds the [index] to [_selectedIndexes], or removes it if it's already
  /// there.
  void tap(int index) {
    print('taped');
    if (_selectedIndexes.contains(index)) {
      _selectedIndexes.remove(index);
    } else {
      _selectedIndexes.add(index);
    }
  }

  /// Adds the [index] to [_selectedIndexes] and allows [updateDrag] calls.
  void startDrag(int index) {
    _dragStartIndex = _dragEndIndex = index;

    if (_selectedIndexes.contains(index)) {
      _selectedIndexes.remove(index);
      _selectPositive = false;
    } else {
      _selectedIndexes.add(index);
      _selectPositive = true;
    }
    //_selectedIndexes.add(index);
  }

  /// Updates the [_selectedIndexes], adding/removing one or more indexes, based
  /// on [index], [dragStartIndex] and [dragEndIndex].
  ///
  /// Does nothing if:
  ///
  ///   * [index] is negative.
  ///   * Drag didn't start.
  void updateDrag(int index) {
    if (index < 0) return;
    if ((_dragStartIndex == -1) || (_dragEndIndex == -1)) return;

    // If the drag is both forward and backward, drag to the start index,
    // and then continue the drag, whether it is forward or backward.
    if ((index < dragStartIndex) && (index < dragEndIndex) ||
        (index > dragStartIndex) && (index > dragEndIndex)) {
      _updateDragForwardOrBackward(_dragStartIndex);
      _dragEndIndex = _dragStartIndex;
    }

    _updateDragForwardOrBackward(index);
    _dragEndIndex = index;
  }

  /// Finishes the current drag.
  void endDrag() {
    temporaryIndexes = {};
    _dragStartIndex = -1;
    _dragEndIndex = -1;
  }

  /// Updates the [_selectedIndexes], adding/removing one or more indexes, based
  /// on [index], [dragStartIndex] and [dragEndIndex].
  ///
  /// This cannot handle a drag that is both forward and backward (and vice
  /// versa). It's possible to do so by, while dragging, jumping from an index
  /// bigger than the start index to an index smaller that the start index.
  void _updateDragForwardOrBackward(int index) {
    final indexesDraggedBy = intSetFromRange(index, _dragEndIndex);

    // ignore: avoid_positional_boolean_parameters
    void removeIndexesDraggedByExceptTheCurrent(bool positive) {
      if (positive) {
        // if (temporaryIndexes.contains(index)) {
        //   temporaryIndexes.remove(index);
        // } else {

        // }

        // ignore: avoid_function_literals_in_foreach_calls
        if (_selectPositive) {
          indexesDraggedBy.remove(index);
          indexesDraggedBy.forEach((element) {
            if (temporaryIndexes.contains(element)) {
              temporaryIndexes.remove(element);
            } else {
              _selectedIndexes.remove(element);
            }
          });
        } else {
          indexesDraggedBy.forEach((element) {
            if (!_selectedIndexes.contains(element)) {
              temporaryIndexes.add(element);
            }
          });
          _selectedIndexes.removeAll(indexesDraggedBy);
        }

        // _selectedIndexes.removeAll(indexesDraggedBy);
      } else {
        // ignore: avoid_function_literals_in_foreach_calls
        if (_selectPositive) {
          indexesDraggedBy.forEach((element) {
            if (_selectedIndexes.contains(element)) {
              temporaryIndexes.add(element);
            }
          });
          _selectedIndexes.addAll(indexesDraggedBy);
        } else {
          indexesDraggedBy.remove(index);
          indexesDraggedBy.forEach((element) {
            if (temporaryIndexes.contains(element)) {
              temporaryIndexes.remove(element);
            } else {
              _selectedIndexes.add(element);
            }
          });
        }
      }
    }

    final isSelectingForward = index > _dragStartIndex;
    final isSelectingBackward = index < _dragStartIndex;

    if (isSelectingForward) {
      final isUnselecting = index < _dragEndIndex;
      if (isUnselecting) {
        removeIndexesDraggedByExceptTheCurrent(_selectPositive);
      } else {
        // _selectedIndexes.addAll(indexesDraggedBy);
        removeIndexesDraggedByExceptTheCurrent(!_selectPositive);
      }
    } else if (isSelectingBackward) {
      final isUnselecting = index > _dragEndIndex;
      if (isUnselecting) {
        removeIndexesDraggedByExceptTheCurrent(_selectPositive);
      } else {
        removeIndexesDraggedByExceptTheCurrent(!_selectPositive);
        // _selectedIndexes.addAll(indexesDraggedBy);
      }
    } else {
      removeIndexesDraggedByExceptTheCurrent(_selectPositive);
    }
  }
}

/// Information about the grid selection.
@immutable
class Selection {
  /// Creates a new [Selection].
  Selection(Set<int> selectedIndexes)
      : selectedIndexes = UnmodifiableSetView(Set.of(selectedIndexes));

  /// Creates a new [Selection] with no selected items.
  const Selection.empty() : selectedIndexes = const {};

  /// Grid indexes that are selected.
  final Set<int> selectedIndexes;

  /// Amount of selected indexes.
  int get amount => selectedIndexes.length;

  /// Whether the grid is currently in select mode.
  bool get isSelecting => amount > 0;

  @override
  String toString() => 'Selection{_selectedIndexes: $selectedIndexes}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Selection &&
          runtimeType == other.runtimeType &&
          setEquals(selectedIndexes, other.selectedIndexes);

  @override
  int get hashCode => const SetEquality<int>().hash(selectedIndexes);
}
