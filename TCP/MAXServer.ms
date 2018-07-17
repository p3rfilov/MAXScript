/*---------------------------------------------------------------
Name: MAXServer

Description:
TCP Server (Listener) for 3ds Max

Usage:
Run this script on a open scene or during startup
3dsmax.exe -U MAXScript MAXServer.ms

*/---------------------------------------------------------------


fn TCPListener =
(
	IPAddress = DotNetClass "System.Net.IPAddress"
	theIPAddress = IPAddress.Parse "127.0.0.1"
	theTcpListener = DotNetObject "System.Net.Sockets.TcpListener" theIPAddress 7777
	theTcpListener.Start()
	theString = ""
	theSocket = ""
	while theString != "exit" do
	(
		theSocket = theTcpListener.AcceptSocket() -- the listener dies on startup. Moved socket creation inside the while loop
		theByteStream = DotNetObject "System.Byte[]" 1024
		theSocket.Receive theByteStream
		Encoding = DotnetClass "System.Text.Encoding"
		theString = trimright (Encoding.UTF8.GetString(theByteStream))
		if theString != "" do
		(
			try(execute theString)catch(print "Could not execute command!")
			theSocket.Disconnect(true)
			theSocket = theTcpListener.AcceptSocket()
		)
		theSocket.Disconnect(true)
	)
	try(theSocket.Disconnect(true))catch()
	theTcpListener.Stop()
)

fn setupBackgroundWorker TCPL =
(
	BackgroundWorker = DotNetObject "System.ComponentModel.BackgroundWorker"
	DotNet.AddEventHandler BackgroundWorker "DoWork" TCPL
	BackgroundWorker.WorkerSupportsCancellation = true
	BackgroundWorker.RunWorkerAsync()
)

-- server = setupBackgroundWorker TCPListener
TCPListener() -- run listener on the main thread

