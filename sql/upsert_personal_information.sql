INSERT INTO PersonalInformation (
	public_key_name,
	property,
	value,
	date,
	signature
) VALUES (
	?1,
	?2,
	?3,
	?4,
	?5
) ON CONFLICT(public_key_name, property) DO UPDATE SET
	value = ?3,
	date = ?4,
	signature = ?5
WHERE
	public_key_name = ?1
AND
	property = ?2
