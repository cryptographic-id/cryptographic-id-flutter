CREATE TABLE PublicKeys (
	name TEXT PRIMARY KEY,
	slot INT NOT NULL,
	public_key BLOB UNIQUE NOT NULL,
	date TIMESTAMP NOT NULL,
	signature BLOB NOT NULL,
	deleted BOOLEAN DEFAULT FALSE NOT NULL
);

CREATE TABLE PersonalInformation (
	public_key_name TEXT REFERENCES PublicKeys(name),
	property TEXT NOT NULL,
	value TEXT NOT NULL,
	date TIMESTAMP NOT NULL,
	signature BLOB NOT NULL,
	PRIMARY KEY(public_key_name, property)
);
