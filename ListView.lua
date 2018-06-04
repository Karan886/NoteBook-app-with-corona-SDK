local composer = require "composer"
local sceneName = ...
local scene = composer.newScene(sceneName)

local widget = require "widget"

local w_ = display.contentWidth
local h_ = display.contentHeight
local w = w_/2
local h = h_/2
local barHeight = 70

local color = {75,189,238}

local sqlite3 = require "sqlite3"
local path = system.pathForFile("data.db",system.DocumentsDirectory)
local db = sqlite3.open(path)

local tableSetup = [[CREATE TABLE IF NOT EXISTS list(id INTEGER PRIMARY KEY autoincrement,title,body,date,modified);]]
db:exec(tableSetup)

local tableView

local function onSystemEvent( event )
    if ( event.type == "applicationExit" ) then
        if ( db and db:isopen() ) then
            db:close()
        end
    end
end

function buttonHandler(event)
	if(event.phase == "ended")then
		if(event.target.id == "addNote")then
			composer.gotoScene("EditText",{params = {Mode = "new"}})
		end
	end
end


function onRowRender(event)

	local row = event.row
	local index = row.index
	local displayText = "Note - 1"


	if(row.params.Title == "")then
		displayText = "Note - "..index
	else
		displayText = row.params.Title
	end

	row.title_text = display.newText(row,displayText,0,0,native.systemFont,13)
	row.title_text:setFillColor(0,0,0)
	row.title_text.x = row.x+20
	row.title_text.y = 10
	row.title_text.anchorX = 0
	row:insert(row.title_text)

	row.date_text = display.newText(row.params.Date,0,0,native.systemFont,10)
	row.date_text:setFillColor(0.5,0.5,0.5)
	row.date_text.x = row.x+20
	row.date_text.y = 40
	row.date_text.anchorX = 0
	row:insert(row.date_text)

	row.modified_text = display.newText(row,"Modified:\n"..row.params.Modified,0,0,native.systemFont,10)
	row.modified_text:setFillColor(0.5,0.5,0.5)
	row.modified_text.x = row.x+200
	row.modified_text.y = 10
	row.modified_text.anchorX = 0
	row:insert(row.modified_text)


	function optionsHandler(event)
		if(event.phase == "ended")then

			if(event.target.id == "deleteButton")then

				tableView:deleteRow(index)
				db:exec([[DELETE FROM list WHERE id=']]..row.params.ID..[[']])

			elseif(event.target.id == "editButton")then

				composer.gotoScene("EditText",{params = {Mode = "edit", Id = row.params.ID, title = row.title_text.text, body = row.params.Body}})

			elseif(event.target.id == "cancelButton")then

				row.button_delete.alpha = 0
				row.button_edit.alpha = 0
				row.modified_text.alpha = 1
				row.title_text.alpha = 1
				row.date_text.alpha = 1
				row.button_cancel.alpha = 0

			end
		end
	end

	row.button_delete = widget.newButton{
		left = w_-300,
		top = 5,
		label = "DELETE",
		font = "AbrilFatface-Regular",
		labelColor = {default = {1,1,1}},
		fontSize = 15,
		shape = "rect",
		width = 70,
		height = row.height - 10,
		fillColor = {default = {1,0,0,0.6}, over= {1,0,0,0.3}},
		id = "deleteButton",
		onEvent = optionsHandler
	}

	row.button_edit = widget.newButton{

		left = w_-200,
		top = 5,
		label = "EDIT",
		font = "AbrilFatface-Regular",
		labelColor = {default = {1,1,1}},
		fontSize = 15,
		shape = "rect",
		width = 70,
		height = row.height - 10,
		fillColor = {default = {0.6,0.6,0.6,0.6}, over = {0.6,0.6,0.6,0.3}},
		id = "editButton",
		onEvent = optionsHandler

	}

	row.button_cancel = widget.newButton{

		left = w_-100,
		top = 5,
		label = "CANCEL",
		font = "AbrilFatface-Regular",
		labelColor = {default = {1,1,1}},
		fontSize = 15,
		shape = "rect",
		width = 70,
		height = row.height - 10,
		fillColor = {default = {0.6,0.3,0.8,0.6}, over = {0.6,0.3,0.8,0.3}},
		id = "cancelButton",
		onEvent = optionsHandler

	}


	row.button_delete.alpha = 0
	row.button_edit.alpha = 0
	row.button_cancel.alpha = 0


	row:insert(row.button_delete)
	row:insert(row.button_edit)
	row:insert(row.button_cancel)

end

function onRowTouch(event)

	local row = event.row
	local index = row.index
	if(event.phase == "press")then

		row.button_delete.alpha = 1
		row.button_edit.alpha = 1
		row.button_cancel.alpha = 1
		row.title_text.alpha = 0
		row.date_text.alpha = 0
		row.modified_text.alpha = 0
	
	end
end

function displayList()

	for row in db:nrows("SELECT * FROM list") do
	
		local params = {ID = row.id, Title = row.title, Body = row.body, Date = row.date, Modified = row.modified}
		tableView:insertRow({
			rowHeight = 50,
			params = params
		})
	
	end

end


function scene:create(event)
	local sceneGroup = self.view

	local rect = display.newRect(0,0,w_,barHeight)
	rect.y = h-(h+35)
	rect.anchorX = 0
	rect:setFillColor(color[0],color[1],color[2])

	local button_add = widget.newButton{
		width = 20,
		height = 20,
		left = w_-25,
		top = h_-(h_+35),
		defaultFile = "Images/add_icon.png",
		overFile = "Images/add_icon_over.png",
		id = "addNote",
		onEvent = buttonHandler
	}

	local bg = display.newRect(0,0,w_,h_)
	bg.anchorX,bg.anchorY = 0,0
	bg:setFillColor(0.8,0.8,0.8)

	

	sceneGroup:insert(rect)
	sceneGroup:insert(button_add)
	sceneGroup:insert(bg)
	

end

function scene:show(event)
	local sceneGroup = self.view
	if(event.phase == "will")then
		tableView = widget.newTableView{
		top = h_- (h_- 5),
		onRowRender = onRowRender,
		onRowTouch = onRowTouch
	}

	displayList()
		
	elseif(event.phase == "did")then

	end
	sceneGroup:insert(tableView)
end

function scene:hide(event)
	local sceneGroup = self.view
	if(event.phase == "will")then

	elseif(event.phase == "did")then

	end
end

function scene:destroy(event)
	local sceneGroup = self.view
end

scene:addEventListener("create",scene)
scene:addEventListener("show",scene)
scene:addEventListener("hide",scene)
scene:addEventListener("destroy",scene)
Runtime:addEventListener( "system", onSystemEvent )



return scene