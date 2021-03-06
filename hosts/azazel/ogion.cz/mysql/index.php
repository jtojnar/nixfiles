<?php

function adminer_object() {
	// required to run any plugin
	require_once './plugins/plugin.php';

	// autoloader
	foreach (glob('plugins/*.php') as $filename) {
		require_once __DIR__ . '/' . $filename;
	}

	$plugins = [
		// specify enabled plugins here
		new AdminerEnumOption,
		new AdminerLoginServers([
			'localhost' => [
				'server' => 'localhost',
				// mysql is called server for BC:
				// https://github.com/vrana/adminer/blob/75cd1c3f286c31329072d9b6e3314a5b2b4ff5f0/adminer/drivers/mysql.inc.php#L6
				'driver' => 'server',
			],
		]),
	];

	return new AdminerPlugin($plugins);
}

// include original Adminer or Adminer Editor
require __DIR__ . '/adminer.php';
