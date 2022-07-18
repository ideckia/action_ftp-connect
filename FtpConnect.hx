package;

import js.node.ChildProcess;
import js.node.child_process.ChildProcess as ChildProcessObject;

using api.IdeckiaApi;

typedef Props = {
	@:editable("Will it use secure connection (sftp)?")
	var isSecure:Bool;
	@:editable("Custom FTP executable path. If omitted, will look for 'filezilla' in PATH environment variable.")
	var execPath:String;
	@:editable("The FTP server (with port)")
	var ftpServer:String;
	@:editable("Throgh ftp user")
	var ftpUser:String;
	@:editable("Throgh ftp password")
	var ftpPassword:String;
	@:editable("Color definitions", {connected: 'ff00aa00', disconnected: 'ffaa0000'})
	var color:{connected:String, disconnected:String};
}

@:name('ftp-connect')
@:description('Connect to FTP in a simple and fast way.')
class FtpConnect extends IdeckiaAction {
	var execPath:String;

	var executingProcess:ChildProcessObject;

	override public function init(initialState:ItemState):js.lib.Promise<ItemState> {
		return new js.lib.Promise((resolve, reject) -> {
			if (props.execPath == null) {
				var envPath = Sys.getEnv('PATH').toLowerCase();

				if (envPath.indexOf('filezilla') == -1) {
					var msg = 'Could not find Filezilla (default) in the PATH enviroment variable. Configure your ftp executable with execPath property.';
					server.dialog.error('FTP error', msg);
					reject(msg);
				}

				execPath = 'filezilla';
			} else {
				execPath = props.execPath;
			}

			initialState.bgColor = props.color.disconnected;

			resolve(initialState);
		});
	}

	public function execute(currentState:ItemState):js.lib.Promise<ItemState> {
		return new js.lib.Promise((resolve, reject) -> {
			if (execPath == null)
				reject('No ftp command found. Define it in the action properties (execPath).');

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
				executingProcess.on('error', reject);

				currentState.bgColor = props.color.connected;
			} else {
				killProcess(executingProcess.pid);
				currentState.bgColor = props.color.disconnected;
			}

			resolve(currentState);
		});
	}

	function buildCommand() {
		var cmd = execPath;
		if (props.isSecure)
			cmd += ' sftp://';
		else
			cmd += ' ftp://';

		if (props.ftpUser != null) {
			cmd += '${props.ftpUser}';
			if (props.ftpPassword != null)
				cmd += ':${props.ftpPassword}';

			cmd += '@';
		}
		cmd += props.ftpServer;

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
