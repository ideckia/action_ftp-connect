package;

import js.node.ChildProcess;
import js.node.child_process.ChildProcess as ChildProcessObject;

using api.IdeckiaApi;

typedef Props = {
	@:editable("Will it use secure connection (sftp)?")
	var is_secure:Bool;
	@:editable("FTP executable path.", "filezilla")
	var executable_path:String;
	@:editable("The FTP server (with port)")
	var ftp_server:String;
	@:editable("Throgh ftp user")
	var ftp_user:String;
	@:editable("Throgh ftp password")
	var ftp_password:String;
	@:editable("Color definitions", {connected: 'ff00aa00', disconnected: 'ffaa0000'})
	var color:{connected:String, disconnected:String};
}

@:name('ftp-connect')
@:description('Connect to FTP in a simple and fast way.')
class FtpConnect extends IdeckiaAction {
	var executingProcess:ChildProcessObject;

	override public function init(initialState:ItemState):js.lib.Promise<ItemState> {
		return new js.lib.Promise((resolve, reject) -> {
			initialState.bgColor = props.color.disconnected;

			resolve(initialState);
		});
	}

	public function execute(currentState:ItemState):js.lib.Promise<ItemState> {
		return new js.lib.Promise((resolve, reject) -> {
			var options:ChildProcessSpawnOptions = {
				shell: true,
				detached: true,
				stdio: Ignore
			}

			if (executingProcess == null) {
				var cmd = buildCommand();
				server.log.debug('Connecting with ftp command: [${cmd}]');
				executingProcess = ChildProcess.spawn(cmd, options);
				executingProcess.unref();
				executingProcess.on('close', () -> {
					currentState.bgColor = props.color.disconnected;
					executingProcess = null;
					server.updateClientState(currentState);
				});
				executingProcess.on('error', (error) -> {
					var msg = 'Error connecting to ftp: $error';
					server.dialog.error('FTP error', msg);
					reject(msg);
				});

				currentState.bgColor = props.color.connected;
			} else {
				killProcess(executingProcess.pid);
				currentState.bgColor = props.color.disconnected;
			}

			resolve(currentState);
		});
	}

	function buildCommand() {
		var cmd = props.executable_path;
		if (props.is_secure)
			cmd += ' sftp://';
		else
			cmd += ' ftp://';

		if (props.ftp_user != null) {
			cmd += '${props.ftp_user}';
			if (props.ftp_password != null)
				cmd += ':${props.ftp_password}';

			cmd += '@';
		}
		cmd += props.ftp_server;

		return cmd;
	}

	function killProcess(pid:Int, signal:String = 'SIGKILL') {
		if (Sys.systemName() == "Windows") {
			ChildProcess.exec('taskkill /PID ${pid} /T /F', (error, _, _) -> {
				if (error != null) {
					server.dialog.error('FTP error', 'Error killing process: $error');
				}
			});
		} else {
			// see https://nodejs.org/api/child_process.html#child_process_options_detached
			// If pid is less than -1, then sig is sent to every process in the process group whose ID is -pid.
			js.Node.process.kill(-pid, 'SIGKILL');
		}
	}
}
