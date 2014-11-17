{$, $$, View, SelectListView, EditorView} = require 'atom'
path = require 'path'

module.exports =
class EnableView extends SelectListView
  emp_socket_server: null

  initialize: (serializeState, @emp_socket_server) ->
    # console.log 'enable view process initial'
    super
    @addClass('overlay from-top')
    @setMaxItems(20)
    atom.workspaceView.command "emp-debugger:enable-view", => @enable_view()


  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @cancel()
    @remove()

  enable_view: ->
    # console.log "enable_view"
    if @hasParent()
      @cancel()
    else
      @setItems(@get_view_items())
      @storeFocusedElement()
      atom.workspaceView.append(this)
      @focusFilterEditor()

  get_view_items: ->
    # console.log @emp_socket_server.get_client_map()
    # console.log @emp_socket_server.get_client_map().get_all_views()
    tmp_map = @emp_socket_server.get_client_map().get_all_views()
    re_map = new Array()
    index = 0
    len = tmp_map.length
    loop
      break if len is 0
      len -= 1
      re_map[index] = tmp_map[len]
      index += 1
    re_map

  # Public: Get the property name to use when filtering items.
  #
  # This method may be overridden by classes to allow fuzzy filtering based
  # on a specific property of the item objects.
  #
  # For example if the objects you pass to {::setItems} are of the type
  # `{"id": 3, "name": "Atom"}` then you would return `"name"` from this method
  # to fuzzy filter by that property when text is entered into this view's
  # editor.
  #
  # Returns the property name to fuzzy filter by.
  getFilterKey: ->
    console.log "get key"
    'index'

  # Public: Create a view for the given model item.
  #
  # This method must be overridden by subclasses.
  #
  # This is called when the item is about to appended to the list view.
  #
  # item - The model item being rendered. This will always be one of the items
  #        previously passed to {::setItems}.
  #
  # Returns a String of HTML, DOM element, jQuery object, or View.
  viewForItem: (item) ->
    # console.log "view item"
    # console.log item
    icon_class = "status-added icon-diff-added"
    icon_class =  "status-ignored icon-diff-ignored" unless !item.readed
    label_name = ''
    label_path = ''
    if item.name
      label_name = item.name
      label_path = "<div class=\"secondary-line no-icon\">Path: #{item.dir}</div>"
    else
      label_name = item.index
      label_path = ""


    "<li class=\"two-lines\">
         <div class=\"status icon #{icon_class}\"></div>
         <div class=\"primary-line icon icon-file-text\">#{label_name}</div>
         <div class=\"secondary-line no-icon\">From client: ##{item.fa_address}:#{item.fa_from}</div>" +label_path

  # Public: Callback function for when an item is selected.
  #
  # This method must be overridden by subclasses.
  #
  # item - The selected model item. This will always be one of the items
  #        previously passed to {::setItems}.
  #
  # Returns a DOM element, jQuery object, or {View}.
  confirmed: (item) ->
    # console.log("#{item.index} was selected")
    # console.log item.readed
    item.set_view_readed()
    @cancel()
    @initial_new_pane(item)

  confirmSelection: ->
    # console.log "selections~"
    item = @getSelectedItem()
    if item?
      @confirmed(item)
    else
      @cancel()

  cancelled: ->
    @filterEditorView.getEditor().setText('')
    @filterEditorView.updateDisplay()


  # initial a new editor pane
  initial_new_pane: (item)->
    tmp_editor = null
    # atom.open({pathsToOpen: [pathToOpen], newWindow: true})
    if dest_file_path = item.dir
      project_path = atom.project.getPath()
      tmp_file_path = path.join project_path, dest_file_path
      # test_path = path.join project_path, 'test.xhtml'
      changeFocus = true
      tmp_editor = atom.workspaceView.openSync(tmp_file_path, { changeFocus })
    else
      tmp_editor = atom.workspace.openSync()

    tmp_editor["emp_live_view"] = item
    tmp_editor["emp_live_script_name"] = null
    tmp_editor["emp_live_script"] = null
    # console.log tmp_editor
    tmp_editor.setText(item.view)
    gramers = @getGrammars()
    tmp_editor.setGrammar(gramers[0]) unless gramers[0] is undefined

  # set the opened editor grammar, default is HTML
  getGrammars: ->
    grammars = atom.syntax.getGrammars().filter (grammar) ->
      (grammar isnt atom.syntax.nullGrammar) and
      grammar.name is 'HTML'

    # grammars.sort (grammarA, grammarB) ->
    #   if grammarA.scopeName is 'text.plain'
    #     -1
    #   else if grammarB.scopeName is 'text.plain'
    #     1
    #   else
    #     grammarA.name?.localeCompare?(grammarB.name) ? grammarA.scopeName?.localeCompare?(grammarB.name) ? 1

    grammars
