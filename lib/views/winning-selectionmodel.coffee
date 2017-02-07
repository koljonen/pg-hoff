SlickGrid = require 'bd-slickgrid/grid'

class WinningSelectionModel
    onSelectedRangesChanged: null
    activeRange: null
    activeRangeComplete: false
    ranges: []
    grid : null
    lastCell: {}
    startCell: {}

    init: (grid) =>
        @grid = grid
        @grid.onClick.subscribe(@handleGridClick)
        @grid.onDblClick.subscribe(@onDoubleClick)
        @grid.onMouseEnter.subscribe(@onMouseEnter)
        @grid.onKeyDown.subscribe(@onKeyDown)
        @grid.onMouseDown.subscribe(@onMouseDown)
        @onSelectedRangesChanged = new Slick.Event

    onMouseDown: (e, args, local) =>
        cell = @grid.getCellFromEvent(e)
        @lastCell = x: cell.cell, y: cell.row
        @dragCell = cell
        return unless cell?

        unless e.shiftKey or e.metaKey
            @activeRange = null
            @ranges = []

        if e.metaKey and @activeRange
            @ranges.push @activeRange
            @activeRange = null

        unless @activeRange?
            @startCell = x: cell.cell, y: cell.row
            @activeRange = new Slick.Range(cell.row, cell.cell, cell.row, cell.cell)

        else if not local?
            @increaseRange cell.cell, cell.row

         @onSelectedRangesChanged.notify @ranges.concat( [ @activeRange ] )

    increaseRange: (x, y) =>
        @activeRange.fromRow = Math.min(@startCell.y, y)
        @activeRange.toRow = Math.max(@startCell.y, y)

        @activeRange.fromCell = Math.min(@startCell.x, x)
        @activeRange.toCell = Math.max(@startCell.x, x)

    handleGridClick: (e, args) =>
        @onMouseDown(e, args, true)

    onKeyDown: (e, args) =>
        data = @grid.getData()
        columns = @grid.getColumns()
        if @lastCell? and ( [ 37, 38, 39, 40 ].indexOf e.keyCode ) >= 0
            deltaX = 0
            deltaY = 0
            if e.keyCode == 37 and @lastCell? # LEFT
                deltaX = -1
            else if e.keyCode == 38 and @lastCell? # UP
                deltaY = -1
            else if e.keyCode == 39 and @lastCell? # RIGHT
                deltaX = 1
            else if e.keyCode == 40 and @lastCell? # DOWN
                deltaY = 1

            outOfBounds = true
            unless @lastCell.x + deltaX < 0 or @lastCell.x + deltaX >= columns.length
                @lastCell.x = @lastCell.x + deltaX
                outOfBounds = false

            unless @lastCell.y + deltaY < 0 or @lastCell.y + deltaY >= data.length
                @lastCell.y = @lastCell.y + deltaY
                outOfBounds = false

            unless outOfBounds
                if e.shiftKey
                    @increaseRange @lastCell.x, @lastCell.y
                else
                    @startCell = x: @lastCell.x, y: @lastCell.y
                    @activeRange = new Slick.Range @lastCell.y, @lastCell.x, @lastCell.y, @lastCell.x

                @onSelectedRangesChanged.notify [ @activeRange ]
        if e.keyCode == 27
            @ranges = []
            @activeRange = null
            @onSelectedRangesChanged.notify @ranges
        if e.keyCode == 65 and e.metaKey and data.length > 0
            @ranges = []
            @activeRange = new Slick.Range 0, 0, data.length - 1, columns.length - 1
            @onSelectedRangesChanged.notify [ @activeRange ]
        if (e.metaKey or e.ctrlKey) and e.keyCode == 67
            selectedColumns = []
            output = []
            data = @grid.getData()
            columns = @grid.getColumns()
            for range in @ranges.concat( [ @activeRange ] )
                for x in [range.fromCell..range.toCell]
                    for y in [range.fromRow..range.toRow]
                        selectedColumns.push({x: x, y:y})
            for cell in selectedColumns
                output.push(data[cell.y][columns[cell.x]["field"]]?.toString())
            atom.clipboard.write(output.join(", ").toString())
            #atom.clipboard.write(@data[args.row][@columns[args.cell]["field"]].toString())


    onDoubleClick: (e, args) =>

    onClick: (e, args) =>

    onMouseEnter: (e, args) =>
        return unless e.buttons == 1 and e.button == 0

        cell = @grid.getCellFromEvent(e)
        return unless cell?
        @lastCell = x: cell.cell, y: cell.row

        @activeRange = null
        #@ranges = []

        if e.metaKey and @activeRange
            @ranges.push @activeRange
            @activeRange = null

        @activeRange = new Slick.Range(@dragCell.row, @dragCell.cell, @dragCell.row, @dragCell.cell)

        @activeRange.fromRow = Math.min(@activeRange.fromRow, cell.row)
        @activeRange.toRow = Math.max(@activeRange.toRow, cell.row)

        @activeRange.fromCell = Math.min(@activeRange.fromCell, cell.cell)
        @activeRange.toCell = Math.max(@activeRange.toCell, cell.cell)
        @activeRangeComplete = true

        @onSelectedRangesChanged.notify @ranges.concat( [ @activeRange ] )

    destroy: =>

module.exports = WinningSelectionModel
