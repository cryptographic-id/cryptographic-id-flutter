ALTER TABLE DBKeyInfos ADD COLUMN fingerprint TEXT NOT NULL DEFAULT '';
ALTER TABLE DBKeyInfos ADD COLUMN duplicate INT NOT NULL DEFAULT 0;