/*---------------------------------------------------------------
Name: MAXclient

Description:
TCP Client for 3ds MAX

Usage:
socket = MAXsocket "127.0.0.1" 7777
socket.send <MAXScript command as string>
socket.send "exit" -- stop TCP Listener

*/---------------------------------------------------------------

struct MAXsocket
(
	ip_address = "127.0.0.1",
	port = 7777,
	fn connect ip_string port_int =
	(
		try
		(
			sock = dotNetObject "System.Net.Sockets.Socket" ( dotnetclass "System.Net.Sockets.AddressFamily" ).InterNetwork ( dotnetclass "System.Net.Sockets.SocketType" ).Stream ( dotnetclass "System.Net.Sockets.ProtocolType" ).Tcp
			sock.Connect ip_string port_int
		)
		catch(return undefined)
		return sock
	),
	fn send data = 
	(
		ascii_encoder = dotNetObject "System.Text.ASCIIEncoding"
		bytes = ascii_encoder.GetBytes(data as string)
		socket = connect ip_address port
		if socket != undefined then
		(
			result = socket.Send bytes
			socket.close()
			sleep 0.001
		)
		else
		(
			print "Could not create socket! Data was not sent!"
		)
	)
)

socket = MAXsocket "127.0.0.1" 7777
socket.send "exit"

-- for i in 1 to 100000 by 100 do
-- (
-- 	socket = MAXsocket "127.0.0.1" 7777
-- 	cmd = stringstream ""
-- 	format "box pos:[%, %, 0]" i i to:cmd
-- 	socket.send cmd
-- )
