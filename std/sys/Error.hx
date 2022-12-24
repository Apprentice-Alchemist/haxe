package sys;

enum Error {
	Unsupported;
	/**
		The requested operation would be blocking.
		Try again later.
	**/
	Blocked;
	Unknown;
}