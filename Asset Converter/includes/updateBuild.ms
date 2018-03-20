/*---------------------------------------------------------------
Purpose: Copies a package (directory) to a desired location.
Compares build versions of source and destination packages
(__version.txt)
Input: source folder; destination folder
Return: None
*/---------------------------------------------------------------
fn updateBuild source destination =
(
	fn copyDirectory source destination =
	(
		xcopy = "xcopy " + "\"" + source + "\" \"" + destination + "\" " + "/O /X /E /H /K /i /y"
		res = DOSCommand xcopy
		if res != 0 then print ("Some error occurred while copying " + source)
		else print "Build version has successfully been updated"
	)
	
	fn getVersion location =
	(
		versionFile = location + "\\__version.txt"
		f = openFile versionFile
		if f != undefined then
		(
			ver = readLine f
			close f
			return ver
		)
		else
		(
			print ("could not open: " + versionFile)
			return "0"
		)
	)
	
	if not doesFileExist destination then
	(		
		copyDirectory source destination
	)
	else
	(
		oldVer = getVersion destination
		newVer = getVersion source
		if oldVer != newVer do 
			copyDirectory source destination
	)
)