package util;

class Logging {

    public static function print(message: String): Void {
        Sys.println('\x1b[37m' + message + '\x1b[0m');
    }

    public static function error(message: String): Void {
        Sys.println('\x1b[31m[ERROR] ' + message + '\x1b[0m');
    }

    public static function warn(message: String): Void {
        Sys.println('\x1b[33m[WARN] ' + message + '\x1b[0m');
    }

    public static function info(message: String): Void {
        Sys.println('\x1b[34m[INFO] \x1b[37m' + message + '\x1b[0m');
    }

    public static function success(message: String): Void {
        Sys.println('\x1b[32m[SUCCESS] ' + message + '\x1b[0m');
    }

    public static function debug(message: String): Void {
        Sys.println('\x1b[36m[DEBUG] ' + message + '\x1b[0m');
    }

}
