/*---------------------------------------------------------------
Name: My ToolBox v1.0

Description:
Stores links to your favourite scripts in one place.
The scripts are not moved or copied, which is essential
in a continuous development environment.

To Do:
- Replace maxscript listbox with a multi-column dotNetObject.
  This will remove the need to have in-memory scriptArray
- Implement whole folder structure imports

Author: Andrej Perfilov [perfilov3d.com]
Date: 17-12-2017
*/---------------------------------------------------------------

try(destroydialog myToolbox)catch()

rollout myToolbox "My ToolBox v1.0" width:200 height:296
(
	dropdownList 'ddl_category' "Category" pos:[8,8] width:128 height:40 align:#left
	button 'btn_addCat' "+" pos:[144,25] width:24 height:24 align:#left
	button 'btn_delCat' "-" pos:[168,25] width:24 height:24 align:#left
	listbox 'lbx_scripts' "Scripts" pos:[8,56] width:184 height:14 align:#left
	button 'btn_add' "+" pos:[8,264] width:24 height:24 align:#left
	button 'btn_del' "-" pos:[32,264] width:24 height:24 align:#left
	button 'btn_run' "Run" pos:[144,264] width:48 height:24 align:#left
	
	local toolboxDir = (getdir #downloads) + "\\toolBox\\"
	local settingsFile = toolboxDir + "Settings.ini"
	local scriptArray = #()
	
	---------------------------------------- FUNCTIONS ----------------------------------------
	
	/*---------------------------------------------------------------
	Purpose: Illegal character filtering
	Input: String
	Return: Boolean
	*/---------------------------------------------------------------
	fn filter_Text str =
	(
		legalChars = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789_- "
		badChars = filterString str legalChars
		if badChars.count != 0 then
		return false
		else
		return true
	)
	
	fn create_Category dir name =
	(
		file = dir + name + ".txt"
		if not doesFileExist file then
		(
			f = createFile file
			if f != undefined do close f
			return true
		)
		else
		(
			messagebox "This Category already exists!" title:"Duplicate name" beep:false
			return false
		)
	)
	
	fn write_File file arr m:"a" filter:true=
	(
		f = openFile file mode:m
		for i in arr do
		(
			if filter then
				if getFilenameType i == ".ms" or getFilenameType i == ".mse" do
					format "%\n" i to:f
			else
				format "%\n" i to:f
		)
		close f
	)
	
	/*---------------------------------------------------------------
	Purpose: Reads lines from a given file
	Input: File path, optional buildStruct parameter (if true, builds a struct)
	Return: Array of string or array of structs (buildStruct:true). If read failed - returns undefined
	*/---------------------------------------------------------------
	fn read_File file buildStruct:true =
	(
		struct script (name, path)
		
		strArr = #()
		f = openFile file mode:"r"
		if f != undefined then
		(
			while not eof f do append strArr (readline f)
			close f
			if buildStruct then
				retArr = for i in strArr where i != "" collect (script name:(getFilenameFile i) path:i)
			else retArr = strArr
		)
		else
		(
			messagebox "Could not read file!" title:"Read Failed" beep:false
			gc light:true
		)
		return retArr -- returns undefined if Read Failed
	)
	
	fn store_Settings file dir ddl =
	(
		if ddl.items.count > 0 and ddl.selection > 0 do
		(
			write_File file #(ddl.selected) m:"w" filter:false
		)
	)
	
	fn load_Settings file ddl =
	(
		c = (read_File file buildStruct:false)[1]
		for i = 1 to ddl.items.count do
			if c == ddl.items[i] do ddl.selection = i
	)
	
	fn delete_File file =
	(
		if not (deleteFile file) do
		(
			messagebox ("Could not Delete category " + (getFilenameFile file)) title:"Delete Failed" beep:false
			gc light:true
		)
	)
	
	fn update_Categories dir ddl =
	(
		files = getFiles (dir + "*.txt")
		ddl.items = for i in files collect (getFilenameFile i) 
		if ddl.items.count > 0 and ddl.selection == 0 do ddl.selection = 1
	)
	
	/*---------------------------------------------------------------
	Purpose: Updates script listbox (lbx)
	Input: Root directory, drop-down list, listbox 
	Return: Array of structs (from read_File function)
	*/---------------------------------------------------------------
	fn update_Scripts dir ddl lbx =
	(
		arr = #()
		if ddl.items.count > 0 and ddl.selection > 0 then
		(
			file = dir + ddl.selected + ".txt"
			arr = read_File file
			if arr != undefined do
				lbx.items = sort (for i in arr collect (i.name))
		)
		else lbx.items = #()
		return arr
	)
	
	/*---------------------------------------------------------------
	Purpose: Position child dialog on top of parent
	Input: Child dialog name, parent dialog name
	Return: [x,y] ]Position
	*/---------------------------------------------------------------
	fn get_Center child parent =
	(
		parentPos = GetDialogPos parent
		parentSize = GetDialogSize parent
		parentCenter = parentSize/2 + parentPos
		pos = parentCenter - [(child.width/2) , (child.height/2)]
		return pos
	)
	
	fn get_multipleFiles =
	(
		-- source: http://www.scriptspot.com/bobo/mxs9/dotNet/OpenFileDialog.html
		theDialog = dotNetObject "System.Windows.Forms.OpenFileDialog" --create a OpenFileDialog
		theDialog.title = "Select Script Files" --set the title
		theDialog.Multiselect = true --allow multiple files to be selected
		theDialog.Filter = "Scripts (*.ms)|*.ms|Encripted Scripts (*.mse)|*.mse|All Files (*.*)|*.*" --specify the filter
		theDialog.FilterIndex = 3 --set the filter drop-down list to All Files
		result = theDialog.showDialog() --display the dialog, get result into variable
		theFilenames = theDialog.fileNames --the selected filenames will be returned as an array
		return theFilenames
	)
	
	fn check_Unique files lbx =
	(
		unique = #()
		for i in files do
		(
			n = getFilenameFile i
			if findItem lbx.items n == 0 do append unique i
		)
		if unique.count < files.count do
			messagebox "Scripts with duplicate names were ignored" title:"Duplicate scripts found" beep:false
		return unique
	)
	
	fn run_Script name arr =
	(
		run = false
		for i in arr where not run do
		(
			if i.name == name do
			(
				run = true
				try fileIn i.path
				catch (messagebox "Could not run script!" title:"Run failed" beep:false)
			)
		)
	)
	
	fn remove_Script file lbx arr =
	(
		if lbx.items.count > 0 and lbx.selection > 0 do
		(
			writeArr = #()
			tempArr = lbx.items
			deleteItem tempArr lbx.selection
			for i in tempArr do
			(
				for j in arr do
				(
					if i == j.name do append writeArr j.path
				)
			)
			write_File file writeArr m:"w"
		)
	)
	
	---------------------------------------- ROLLOUTS ----------------------------------------
	
	rollout newCategory "Create New Category" width:216 height:48
	(
		edittext 'edt_cat' "" pos:[8,16] width:152 height:16 align:#left
		button 'btn_ok' "OK" pos:[168,16] width:40 height:16 align:#left
		
		on newCategory open do setFocus edt_cat
		on btn_ok pressed do
		(
			if edt_cat.text != "" then
			(
				if create_Category toolboxDir edt_cat.text do
				(
					try(destroydialog newCategory)catch()
					update_Categories toolboxDir ddl_category
					scriptArray = update_Scripts toolboxDir ddl_category lbx_scripts
				)
			)
			else messagebox "Enter a valid name for the Category" title:"Empty Input" beep:false
		)
		on edt_cat changed text do
		(
			t = filter_Text text
			if not t do edt_cat.text = replace text text.count 1 ""
		)
	)
	
	---------------------------------------- CONTROLS ----------------------------------------
	
	on myToolbox open do
	(
		if not doesFileExist toolboxDir do
		(
			if not makeDir toolboxDir then
				messagebox "Could not create root directory! Make sure Max is run as administrator" title:"Write failed" beep:false
			else
			(
				create_Category toolboxDir "My Scripts"
				update_Categories toolboxDir ddl_category
				store_Settings settingsFile toolboxDir ddl_category
			)
		)
		update_Categories toolboxDir ddl_category
		load_Settings settingsFile ddl_category
		scriptArray = update_Scripts toolboxDir ddl_category lbx_scripts
	)
	on ddl_category selected sel do
	(
		scriptArray = update_Scripts toolboxDir ddl_category lbx_scripts
		store_Settings settingsFile toolboxDir ddl_category
	)
	on btn_addCat pressed do
	(
		try(destroydialog newCategory)catch()
		pos = get_Center newCategory myToolbox
		createdialog newCategory pos:pos parent:myToolbox.hwnd modal:true
	)
	on btn_delCat pressed do
	(
		if ddl_category.items.count > 0 and ddl_category.selection > 0 do
		(
			Y = false
			Y = (queryBox "Remove selected Category?" title:"Remove?" beep:false)
			if Y do
			(
				file = toolboxDir + ddl_category.selected + ".txt"
				delete_File file
				update_Categories toolboxDir myToolbox.ddl_category
				scriptArray = update_Scripts toolboxDir ddl_category lbx_scripts
			)
		)
	)
	on lbx_scripts doubleClicked sel do
	(
		if lbx_scripts.items.count > 0 and sel > 0 do
			run_Script lbx_scripts.selected scriptArray
	)
	on btn_add pressed do
	(
		if ddl_category.items.count > 0 and ddl_category.selection > 0 then
		(
			f = get_multipleFiles()
			if f.count != 0 do
			(
				if ddl_category.items.count > 0 and ddl_category.selection > 0 do
				(
					file = toolboxDir + ddl_category.selected + ".txt"
					scripts = check_Unique f lbx_scripts
					write_File file scripts
					scriptArray = update_Scripts toolboxDir ddl_category lbx_scripts
				)
			)
		)else messagebox "Please create a Category first" title:"Category list empty" beep:false
	)
	on btn_del pressed do
	(
		if ddl_category.items.count > 0 and ddl_category.selection > 0 do
		if lbx_scripts.items.count > 0 and lbx_scripts.selection > 0 do
		(
			Y = false
			Y = (queryBox "Remove selected Script?" title:"Remove?" beep:false)
			if Y do
			(
				file = toolboxDir + ddl_category.selected + ".txt"
				remove_Script file lbx_scripts scriptArray
				scriptArray = update_Scripts toolboxDir ddl_category lbx_scripts
			)
		)
	)
	on btn_run pressed do
	(
		if lbx_scripts.items.count > 0 and lbx_scripts.selection > 0 do
			run_Script lbx_scripts.selected scriptArray
	)
)

createdialog myToolbox
