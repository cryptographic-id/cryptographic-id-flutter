CREATE TABLE PublicKeys (
	id INTEGER PRIMARY KEY,
	name TEXT UNIQUE NOT NULL,
	key TEXT UNIQUE NOT NULL,
	deleted BOOLEAN DEFAULT FALSE NOT NULL
);