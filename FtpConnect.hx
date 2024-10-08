package;

import js.node.ChildProcess;
import js.node.child_process.ChildProcess as ChildProcessObject;

using api.IdeckiaApi;

typedef Props = {
	@:editable("prop_is_secure")
	var is_secure:Bool;
	@:editable("prop_executable_path", "filezilla")
	var executable_path:String;
	@:editable("prop_ftp_server")
	var ftp_server:String;
	@:editable("prop_ftp_user")
	var ftp_user:String;
	@:editable("prop_ftp_password")
	var ftp_password:String;
	var color:{connected:String, disconnected:String};
}

@:name('ftp-connect')
@:description('action_description')
@:localize
class FtpConnect extends IdeckiaAction {
	static var DEFAULT_COLORS:{
		connected:String,
		disconnected:String
	} = Data.embedJson('colors.json');

	var executingProcess:ChildProcessObject;

	override public function init(initialState:ItemState):js.lib.Promise<ItemState> {
		return new js.lib.Promise((resolve, reject) -> {
			if (props.color == null) {
				var colorData = core.data.getJson('colors.json');
				if (colorData != null)
					props.color = colorData;
				else
					props.color = DEFAULT_COLORS;
			}

			initialState.bgColor = props.color.disconnected;

			resolve(initialState);
		});
	}

	public function execute(currentState:ItemState):js.lib.Promise<ActionOutcome> {
		return new js.lib.Promise((resolve, reject) -> {
			var options:ChildProcessSpawnOptions = {
				shell: true,
				detached: true,
				stdio: Ignore
			}

			if (executingProcess == null) {
				var cmd = buildCommand();
				core.log.debug('Connecting with ftp command: [${cmd}]');
				executingProcess = ChildProcess.spawn(cmd, options);
				executingProcess.unref();
				executingProcess.on('close', () -> {
					currentState.bgColor = props.color.disconnected;
					executingProcess = null;
					core.updateClientState(currentState);
				});
				executingProcess.on('error', (error) -> {
					var msg = 'Error connecting to ftp: $error';
					core.dialog.error('FTP error', msg);
					reject(msg);
				});

				currentState.bgColor = props.color.connected;
			} else {
				killProcess(executingProcess.pid);
				currentState.bgColor = props.color.disconnected;
			}

			resolve(new ActionOutcome({state: currentState}));
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
					core.dialog.error('FTP error', 'Error killing process: $error');
				}
			});
		} else {
			// see https://nodejs.org/api/child_process.html#child_process_options_detached
			// If pid is less than -1, then sig is sent to every process in the process group whose ID is -pid.
			js.Node.process.kill(-pid, 'SIGKILL');
		}
	}
}
