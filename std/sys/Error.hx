package sys;

// enum Error {
// 	Unsupported;
// 	/**
// 		The requested operation would be blocking.
// 		Try again later.
// 	**/
// 	Blocked;
// 	Unknown;
// 	/**
// 		Resource was closed.
// 	**/
// 	Closed;
// 	NoPermissions;
// }

class Error extends haxe.Exception {}

class Blocked extends Error {}
class UnknownError extends Error {}
class Closed extends Error {}
class NoPermission extends Error {}