Promise = require('promise')
PgHoffServerRequest     = require './pg-hoff-server-request'

class PgHoffListServersView
    fulfil: null
    reject: null

    constructor: (serializedState) ->
        @element = document.createElement('div')
        @element.classList.add 'pg-hoff-list-servers'

    connect: (panel) ->
        listServersView = @
        return PgHoffServerRequest.Get 'listservers'
            .then (servers) ->
                promise = listServersView.update(servers, listServersView.element)
                panel.show()

                return promise
            .then (selectedServer) ->
                request =
                    alias: selectedServer.alias,
                    authkey: ''

                return PgHoffServerRequest.Post 'connect', request
            .then (response) ->
                if response.errormessage == 'Already connected to server.'
                    response.already_connected = true
                    return response
                else if response.errormessage?
                    throw(response.errormessage)

                return response

    update: (servers, element) ->
        return new Promise( (resolve, reject) ->
            while (element.firstChild)
                element.removeChild(element.firstChild)

            for server of servers
                loc = server
                servers[server].alias = server
                container = element.appendChild document.createElement('div')
                container.classList.add 'server'
                container.setAttribute('alias', server)
                container.onclick = ->
                    s = servers[this.getAttribute('alias')]
                    element.innerHTML = '<div class="connecting">Connecting to ' + s.alias + '...</div>'
                    resolve(s)

                title = container.appendChild document.createElement('div')
                title.classList.add 'title'
                title.textContent = server

                urlContainer = container.appendChild document.createElement('div')
                urlContainer.classList.add 'url-container'

                url = urlContainer.appendChild document.createElement('div')
                url.classList.add 'url'
                url.innerHTML = servers[server].url

                if servers[server].connected
                    connected = urlContainer.appendChild document.createElement('div')
                    connected.classList.add 'connected'
                    connected.innerHTML = 'Connected &#10003;'

                clear = urlContainer.appendChild document.createElement('div')
                clear.classList.add 'clear'
        )

    serialize: ->

    destroy: ->
        @element.remove()

    getElement: ->
        @element

module.exports = PgHoffListServersView
