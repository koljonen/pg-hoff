request = require('request')
Promise = require('promise')
Type = require('./pg-hoff-types').Type

class PgHoffResultsView
    # There are only two rules of PgHoffResultsView...
    # 1. It should update @element on update(resultsets)
    # 2. Never remove @element from DOM

    constructor: (serializedState) ->
        @element = document.createElement('div')
        @element.classList.add('pg-hoff-results-view')
        @element.setAttribute('tabindex', -1)
        @element.classList.add('native-key-bindings')

    resultsets: []

    canTypeBeSorted: (typeCode) ->
        return Type[typeCode]?

    compare: (typeCode, left, right, asc) ->
        return Type[typeCode]?.compare(left, right) * if asc then 1 else -1 ? 0

    sort: (resultset, columnIndex) ->
        ascending = +resultset.columns[columnIndex].ascending = !resultset.columns[columnIndex].ascending

        typeCode = resultset.columns[columnIndex].type_code
        if not Type[typeCode]?.compare?
            console.error('This type is not sortable', typeCode)
            return

        resultset.rows.sort (left, right) =>
            return @compare(typeCode, left[columnIndex], right[columnIndex], ascending)

    createTh: (text, resultsetIndex, columnIndex) ->
        th = document.createElement('th')
        th.textContent = text
        if @canTypeBeSorted(@resultsets[resultsetIndex].columns[columnIndex].type_code)
            th.classList.add('sortable')
            th.textContent += if @resultsets[resultsetIndex].columns[columnIndex].ascending then ' +' else ' -' ? ''

        th.onclick = =>
            @sort @resultsets[resultsetIndex], columnIndex
            @update(@resultsets)

        return th

    createTable: (x, resultsetIndex) ->
        container = document.createElement('div')
        container.classList.add('table')
        container.classList.add('executing')

        if x.executing
            pre = container.appendChild(document.createElement('pre'))
            pre.textContent = 'Executing for ' + x.runtime_seconds + ' seconds...'
            container.classList.add('executing')

            return container

        if not x.complete
            pre = container.appendChild(document.createElement('pre'))
            pre.textContent = 'Waiting to execute...'
            container.classList.add('executing')

        if x.statusmessage?
            status = container.appendChild(document.createElement('div'))
            status.classList.add('status-message')
            status.textContent = "#{x.runtime_seconds} seconds. #{x.statusmessage}"

        table = container.appendChild(document.createElement('table'))

        # Header columns
        if x.columns?
            col_tr = table.appendChild(document.createElement('tr'))
            for c, i in x.columns
                col_tr.appendChild(@createTh(c.name, resultsetIndex, i))

        # Rows
        if x.rows?
            for r in x.rows
                row_tr = table.appendChild(document.createElement('tr'))
                for c, i in r
                    row_tr.appendChild(@createTd(c, x.columns[i].type_code))

        return container

    createTd: (text, typeCode) ->
        td = document.createElement('td')
        td.textContent = text
        td.textContent = Type[typeCode].format(text) if Type[typeCode]?.format and atom.config.get('pg-hoff.formatColumns')

        return td

    update: (resultsets) ->
        @resultsets = resultsets
        while (@element.firstChild)
            @element.removeChild(@element.firstChild)

        @element.appendChild(@createToolbar())
        @element.style.display = 'block'

        for resultset, i in resultsets
            @element.appendChild(@createTable(resultset, i))

    createToolbar: ->
        toolbar = document.createElement('div')
        toolbar.classList.add('toolbar')

        element = @element

        close = toolbar.appendChild(document.createElement('div'))
        close.classList.add('tool')
        close.textContent = 'X'
        close.onclick = =>
            element.style.display = 'none'

        maximize = toolbar.appendChild(document.createElement('div'))
        maximize.classList.add('tool')
        maximize.textContent = '+'
        maximize.onclick = =>
            element.style['max-height'] = '800px'
            element.style['height'] = '800px'

        minimize = toolbar.appendChild(document.createElement('div'))
        minimize.classList.add('tool')
        minimize.textContent = '-'
        minimize.onclick = ->
            element.style['height'] = '150px'
            element.style['max-height'] = '150px'

        # RESTORE
        restore = toolbar.appendChild(document.createElement('div'))
        restore.classList.add('tool')
        restore.textContent = '[]'
        restore.onclick = ->
            element.style['max-height'] = '300px'
            element.style['height'] = '300px'

        clear = toolbar.appendChild(document.createElement('div'))
        clear.classList.add('clear')

        return toolbar

    serialize: ->

    destroy: ->
        @element.remove()

    getElement: ->
        @element

module.exports = PgHoffResultsView
