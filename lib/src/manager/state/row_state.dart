import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

abstract class IRowState {
  List<PlutoRow> get rows;

  FilteredList<PlutoRow> refRows = FilteredList();

  List<PlutoRow> get checkedRows;

  List<PlutoRow> get unCheckedRows;

  bool get hasCheckedRow;

  bool get hasUnCheckedRow;

  /// Property for [tristate] value in [Checkbox] widget.
  bool? get tristateCheckedRow;

  /// Row index of currently selected cell.
  int? get currentRowIdx;

  /// Row of currently selected cell.
  PlutoRow? get currentRow;

  PlutoRowColorCallback? get rowColorCallback;

  int? getRowIdxByOffset(double offset);

  PlutoRow? getRowByIdx(int rowIdx);

  PlutoRow getNewRow();

  List<PlutoRow> getNewRows({
    int count = 1,
  });

  void setRowChecked(
    PlutoRow row,
    bool flag, {
    bool notify = true,
  });

  void insertRows(
    int rowIdx,
    List<PlutoRow> rows, {
    bool notify = true,
  });

  void prependNewRows({
    int count = 1,
  });

  void prependRows(List<PlutoRow> rows);

  void appendNewRows({
    int count = 1,
  });

  void appendRows(List<PlutoRow> rows);

  void removeCurrentRow();

  void removeRows(List<PlutoRow> rows);

  void removeAllRows({bool notify = true});

  void moveRowsByOffset(
    List<PlutoRow> rows,
    double offset, {
    bool notify = true,
  });

  void moveRowsByIndex(
    List<PlutoRow> rows,
    int index, {
    bool notify = true,
  });

  void toggleAllRowChecked(
    bool flag, {
    bool notify = true,
  });

  /// Dynamically change the background color of row by implementing a callback function.
  void setRowColorCallback(PlutoRowColorCallback rowColorCallback);
}

mixin RowState implements IPlutoGridState {
  @override
  List<PlutoRow> get rows => [...refRows];

  @override
  FilteredList<PlutoRow> get refRows => _refRows;

  @override
  set refRows(FilteredList<PlutoRow> setRows) {
    PlutoGridStateManager.initializeRows(refColumns.originalList, setRows);

    _refRows = setRows;
  }

  FilteredList<PlutoRow> _refRows = FilteredList();

  @override
  List<PlutoRow> get checkedRows => refRows.where((row) => row.checked!).toList(
        growable: false,
      );

  @override
  List<PlutoRow> get unCheckedRows =>
      refRows.where((row) => !row.checked!).toList(
            growable: false,
          );

  @override
  bool get hasCheckedRow =>
      refRows.firstWhereOrNull((element) => element.checked!) != null;

  @override
  bool get hasUnCheckedRow =>
      refRows.firstWhereOrNull((element) => !element.checked!) != null;

  @override
  bool? get tristateCheckedRow {
    final length = refRows.length;

    if (length == 0) {
      return false;
    }

    final Set<bool> checkSet = {};

    for (var i = 0; i < length; i += 1) {
      checkSet.add(refRows[i].checked == true);
    }

    return checkSet.length == 2 ? null : checkSet.first;
  }

  @override
  int? get currentRowIdx => currentCellPosition?.rowIdx;

  @override
  PlutoRow? get currentRow {
    if (currentRowIdx == null) {
      return null;
    }

    return refRows[currentRowIdx!];
  }

  PlutoRowColorCallback? _rowColorCallback;

  @override
  PlutoRowColorCallback? get rowColorCallback {
    return _rowColorCallback;
  }

  @override
  int? getRowIdxByOffset(double offset) {
    offset -= bodyTopOffset - scroll!.verticalOffset;

    double currentOffset = 0.0;

    int? indexToMove;

    final int rowsLength = refRows.length;

    for (var i = 0; i < rowsLength; i += 1) {
      if (currentOffset <= offset && offset < currentOffset + rowTotalHeight) {
        indexToMove = i;
        break;
      }

      currentOffset += rowTotalHeight;
    }

    return indexToMove;
  }

  @override
  PlutoRow? getRowByIdx(int? rowIdx) {
    if (rowIdx == null || rowIdx < 0 || refRows.length - 1 < rowIdx) {
      return null;
    }

    return refRows[rowIdx];
  }

  @override
  PlutoRow getNewRow() {
    final cells = <String, PlutoCell>{};

    for (var column in refColumns) {
      cells[column.field] = PlutoCell(
        value: column.type.defaultValue,
      );
    }

    return PlutoRow(cells: cells);
  }

  @override
  List<PlutoRow> getNewRows({
    int count = 1,
  }) {
    List<PlutoRow> rows = [];

    for (var i = 0; i < count; i += 1) {
      rows.add(getNewRow());
    }

    if (rows.isEmpty) {
      return [];
    }

    return rows;
  }

  @override
  void setRowChecked(
    PlutoRow row,
    bool flag, {
    bool notify = true,
  }) {
    final findRow = refRows.firstWhereOrNull(
      (element) => element.key == row.key,
    );

    if (findRow == null) {
      return;
    }

    findRow.setChecked(flag);

    if (notify) {
      notifyListeners();
    }
  }

  @override
  void insertRows(
    int rowIdx,
    List<PlutoRow> rows, {
    bool notify = true,
  }) {
    _insertRows(rowIdx, rows);

    /// Update currentRowIdx
    if (currentCell != null) {
      updateCurrentCellPosition(notify: false);

      // todo : whether to apply scrolling.
    }

    /// Update currentSelectingPosition
    if (currentSelectingPosition != null &&
        rowIdx <= currentSelectingPosition!.rowIdx!) {
      setCurrentSelectingPosition(
        cellPosition: PlutoGridCellPosition(
          columnIdx: currentSelectingPosition!.columnIdx,
          rowIdx: rows.length + currentSelectingPosition!.rowIdx!,
        ),
        notify: false,
      );
    }

    if (notify) {
      notifyListeners();
    }
  }

  @override
  void prependNewRows({
    int count = 1,
  }) {
    prependRows(getNewRows(count: count));
  }

  @override
  void prependRows(List<PlutoRow> rows) {
    _insertRows(0, rows);

    /// Update currentRowIdx
    if (currentCell != null) {
      setCurrentCellPosition(
        PlutoGridCellPosition(
          columnIdx: currentCellPosition!.columnIdx,
          rowIdx: rows.length + currentRowIdx!,
        ),
        notify: false,
      );

      double offsetToMove = rows.length * rowTotalHeight;

      scrollByDirection(PlutoMoveDirection.up, offsetToMove);
    }

    /// Update currentSelectingPosition
    if (currentSelectingPosition != null) {
      setCurrentSelectingPosition(
        cellPosition: PlutoGridCellPosition(
          columnIdx: currentSelectingPosition!.columnIdx,
          rowIdx: rows.length + currentSelectingPosition!.rowIdx!,
        ),
        notify: false,
      );
    }

    notifyListeners();
  }

  @override
  void appendNewRows({
    int count = 1,
  }) {
    appendRows(getNewRows(count: count));
  }

  @override
  void appendRows(List<PlutoRow> rows) {
    _insertRows(refRows.length, rows);

    notifyListeners();
  }

  @override
  void removeCurrentRow() {
    if (currentRowIdx == null) {
      return;
    }

    if (enabledRowGroups) {
      removeRowAndGroupByKey([currentRow!.key]);
    } else {
      refRows.removeAt(currentRowIdx!);
    }

    resetCurrentState(notify: false);

    notifyListeners();
  }

  @override
  void removeRows(
    List<PlutoRow> rows, {
    bool notify = true,
  }) {
    if (rows.isEmpty) {
      return;
    }

    final Set<Key> removeKeys = Set.from(rows.map((e) => e.key));

    if (currentRowIdx != null &&
        refRows.length > currentRowIdx! &&
        removeKeys.contains(refRows[currentRowIdx!].key)) {
      resetCurrentState(notify: false);
    }

    Key? selectingCellKey;

    if (hasCurrentSelectingPosition) {
      selectingCellKey = refRows
          .originalList[currentSelectingPosition!.rowIdx!].cells.entries
          .elementAt(currentSelectingPosition!.columnIdx!)
          .value
          .key;
    }

    if (enabledRowGroups) {
      removeRowAndGroupByKey(removeKeys);
    } else {
      refRows.removeWhereFromOriginal((row) => removeKeys.contains(row.key));
    }

    updateCurrentCellPosition(notify: false);

    setCurrentSelectingPositionByCellKey(selectingCellKey, notify: false);

    currentSelectingRows.removeWhere((row) => removeKeys.contains(row.key));

    if (notify) {
      notifyListeners();
    }
  }

  @override
  void removeAllRows({bool notify = true}) {
    if (refRows.originalList.isEmpty) {
      return;
    }

    refRows.clearFromOriginal();

    resetCurrentState(notify: false);

    if (notify) {
      notifyListeners();
    }
  }

  @override
  void moveRowsByOffset(
    List<PlutoRow> rows,
    double offset, {
    bool notify = true,
  }) {
    int? indexToMove = getRowIdxByOffset(offset);

    moveRowsByIndex(rows, indexToMove, notify: notify);
  }

  @override
  void moveRowsByIndex(
    List<PlutoRow> rows,
    int? indexToMove, {
    bool notify = true,
  }) {
    if (rows.isEmpty || indexToMove == null) {
      return;
    }

    if (indexToMove + rows.length > refRows.length) {
      indexToMove = refRows.length - rows.length;
    }

    if (isPaginated &&
        page > 1 &&
        indexToMove + pageRangeFrom > refRows.originalLength - 1) {
      indexToMove = refRows.originalLength - 1;
    }

    final Set<Key> removeKeys = Set.from(rows.map((e) => e.key));

    refRows.removeWhereFromOriginal((e) => removeKeys.contains(e.key));

    refRows.insertAll(indexToMove, rows);

    int sortIdx = 0;

    for (var element in refRows.originalList) {
      element.sortIdx = sortIdx++;
    }

    updateCurrentCellPosition(notify: false);

    if (onRowsMoved != null) {
      onRowsMoved!(PlutoGridOnRowsMovedEvent(
        idx: indexToMove,
        rows: rows,
      ));
    }

    if (notify) {
      notifyListeners();
    }
  }

  @override
  void toggleAllRowChecked(
    bool? flag, {
    bool notify = true,
  }) {
    for (final row in refRows) {
      row.setChecked(flag == true);
    }

    if (notify) {
      notifyListeners();
    }
  }

  @override
  void setRowColorCallback(PlutoRowColorCallback? rowColorCallback) {
    _rowColorCallback = rowColorCallback;
  }

  void _insertRows(int index, List<PlutoRow> rows) {
    if (rows.isEmpty) {
      return;
    }

    for (final row in rows) {
      row.setState(PlutoRowState.added);
    }

    int safetyIndex = _getSafetyIndexForInsert(index);

    if (enabledRowGroups) {
      insertRowGroup(safetyIndex, rows);
    } else {
      _setSortIdx(rows: rows, start: safetyIndex);

      if (hasSortedColumn) {
        _increaseSortIdxGreaterThanOrEqual(
          rows: refRows.originalList,
          compare: safetyIndex,
          increase: rows.length,
        );
      } else {
        _increaseSortIdx(
          rows: refRows.originalList,
          start: safetyIndex,
          increase: rows.length,
        );
      }

      refRows.insertAll(safetyIndex, rows);

      PlutoGridStateManager.initializeRows(
        refColumns,
        rows,
        forceApplySortIdx: false,
      );
    }

    if (isPaginated) {
      resetPage(notify: false);
    }
  }

  int _getSafetyIndexForInsert(int index) {
    if (index < 0) {
      return 0;
    }

    final originalRowIdx = isPaginated ? index + pageRangeFrom : index;

    if (originalRowIdx > refRows.originalLength) {
      return refRows.originalLength;
    }

    return index;
  }

  void _setSortIdx({
    required List<PlutoRow> rows,
    int start = 0,
  }) {
    for (final row in rows) {
      row.sortIdx = start++;
    }
  }

  void _increaseSortIdx({
    required List<PlutoRow> rows,
    int start = 0,
    int increase = 1,
  }) {
    final length = rows.length;

    for (int i = start; i < length; i += 1) {
      rows[i].sortIdx += increase;
    }
  }

  void _increaseSortIdxGreaterThanOrEqual({
    required List<PlutoRow> rows,
    int compare = 0,
    int increase = 1,
  }) {
    for (final row in rows) {
      if (row.sortIdx < compare) {
        continue;
      }

      row.sortIdx += increase;
    }
  }
}
