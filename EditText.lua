local composer = require "composer"
local sceneName = ...
local scene = composer.newScene(sceneName)

local w_ = display.contentWidth
local h_ = display.contentHeight
local w = w_/2
local h = h_/2
local barHeight = 70

local sqlite3 = require "sqlite3"
local path = system.pathForFile("data.db",system.DocumentsDirectory)
local db = sqlite3.open(path)


local widget = require "widget"


local bin = {}
local fields 

local characterCount = 0
local textGroup

local params
local title = ""
local body = ""

local button_save




local function onSystemEvent( event )
    if ( event.type == "applicationExit" ) then
        if ( db and db:isopen() ) then
            db:close()
        end
    end
end





function saveNote()

	local currentDate = os.date("*t")
	local dateString = currentDate.day.."-"..currentDate.month.."-"..currentDate.year

	if(params.Mode == "new")then


		local saveData = [[INSERT INTO list VALUES(NULL,"]]..title..[[","]]..body..[[","]]..dateString..[[","]]..dateString..[[" );]]
		db:exec(saveData)
		


	elseif(params.Mode == "edit")then

		local updateData = [[UPDATE list SET title= "]]..title..[["WHERE id= "]]..params.Id..[[ "]]
		local updateData_body = [[UPDATE list SET body= "]]..body..[["WHERE id= "]]..params.Id..[[ "]]
		local updateData_modified = [[UPDATE list SET modified= "]]..dateString..[["WHERE id= "]]..params.Id..[[ "]]
		db:exec(updateData)
		db:exec(updateData_body)
		db:exec(updateData_modified)
		

	end

	
end

function buttonHandler(event)
	if(event.phase == "ended")then
		if(event.target.id == "back")then
			composer.gotoScene("ListView",{effect = "slideRight", time = 250})
		elseif(event.target.id == "saveButton")then
			saveNote()
			composer.gotoScene("ListView")
		end
	end
end

function wordCount_Text(x,y,group)

	local textGroup = {}

	textGroup.character_text = display.newText("count: "..characterCount,x,y,"AbrilFatface-Regular",12)
	textGroup.character_text:setFillColor(0.7,0.4,0.3)
	group:insert(textGroup.character_text)

	function textGroup.updateCount()

		textGroup.character_text.text = "count: "..characterCount

	end

	return textGroup
end

function createFields(x,y)

	local fieldGroup = {}

    fieldGroup.title_field = native.newTextField(x,y,250,30)
	fieldGroup.title_field.anchorX = 0
	fieldGroup.title_field.id = "textField"
	fieldGroup.title_field.placeholder = "Title"

	fieldGroup.textBox = native.newTextBox(x-50,y+255,300,h_-100)
	fieldGroup.textBox.anchorX = 0
	fieldGroup.textBox.isEditable = true
	fieldGroup.textBox.id = "textBox"
	fieldGroup.textBox.hasBackground = true
	fieldGroup.textBox.placeholder = "Body Message"
	
	

	if(params.Mode == "edit")then
		
		for row in db:nrows("SELECT * FROM list WHERE id="..params.Id)do
			fieldGroup.title_field.text = row.title
			fieldGroup.textBox.text = row.body
		end

	end

	bin[#bin+1] = fieldGroup.title_field
	bin[#bin+1] = fieldGroup.textBox

	function fieldGroup.onInput(event)
		if(event.phase == "editing" and event.target.id == "textBox")then

			characterCount = event.startPosition
			textGroup.updateCount()
			body = event.text
			


		elseif(event.phase == "submitted" or event.phase == "ended" or event.phase == "editing")then

			if(event.target.id == "textField")then

				title = event.target.text


			elseif(event.target.id == "textBox")then

				body = event.target.text
				
			end
		end
		
	end


	function fieldGroup.destroy()

		for i=1,#bin do

			display.remove(bin[i])

		end

	end

	fieldGroup.textBox:addEventListener("userInput",fieldGroup.onInput)
	fieldGroup.title_field:addEventListener("userInput",fieldGroup.onInput)

	title = fieldGroup.title_field.text
	body = fieldGroup.textBox.text

	return fieldGroup
end


function scene:create(event)

	local sceneGroup = self.view
    

	local rect = display.newRect(0,0,w_,barHeight)
	rect.y = h-(h+35)
	rect.anchorX = 0
	rect:setFillColor(0.9,0.8,0.6)

	local button_back = widget.newButton{
		left = 20,
		top = h-(h+35),
		width = 20,
		height = 20,
		defaultFile = "Images/arrow_default.png",
		overFile = "Images/arrow_over.png",
		id = "back",
		onEvent = buttonHandler
	}

    button_save = widget.newButton{
		top = h-(h+40),
		font = "AbrilFatface-Regular",
		fontSize = 20,
		labelColor = {default = {1,1,1}, over = {0.8,0.8,0.8}},
		textOnly = true,
		id = "saveButton",
		onEvent = buttonHandler
	}

	
	

	local bg = display.newRect(0,0,w_,h_)
	bg.anchorX,bg.anchorY = 0,0
	bg:setFillColor(0.8,0.8,0.8)

	local title_rect = display.newRoundedRect(0,0,w_,65,5)
	title_rect:setFillColor(0.6,0.5,0.5)
	title_rect.x = rect.x
	title_rect.y = rect.y+62
	title_rect.anchorX = 0


	local text_title = display.newText("Title:",30,h-(h-25),"AbrilFatface-Regular",18)
	text_title:setFillColor(0)

	
	sceneGroup:insert(rect)
	sceneGroup:insert(bg)
	sceneGroup:insert(button_back)
	sceneGroup:insert(button_save)
	sceneGroup:insert(title_rect)
	sceneGroup:insert(text_title)

	
	textGroup = wordCount_Text(title_rect.x+30,title_rect.y+43,sceneGroup)

end

function scene:show(event)
	local sceneGroup = self.view
	params = event.params
	if(event.phase == "will")then

		fields = createFields(w-100,h-(h-25))

		if(params.Mode == "new")then

			button_save:setLabel("save")
			button_save.x = w_-27

			title = ""
			body = ""
			

		elseif(params.Mode == "edit")then

			button_save:setLabel("update")
			button_save.x = w_-37

			title = params.title
			body = params.body
			
			characterCount = string.len(body)
			textGroup.updateCount()

			

	end

	elseif(event.phase == "did")then

	end
end

function scene:hide(event)
	local sceneGroup = self.view
	if(event.phase == "will")then
		fields.destroy()
	elseif(event.phase == "did")then
		characterCount = 0
		textGroup.updateCount()
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