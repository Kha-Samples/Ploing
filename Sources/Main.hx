package;

import kha.System;

class Main {
	public static function main() {
		System.init("Ploing", 640, 480, function () {
			new Ploing();
		});
	}
}
