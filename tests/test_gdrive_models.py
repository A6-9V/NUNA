
import unittest
from gdrive_cleanup import DriveFile

class TestDriveFile(unittest.TestCase):
    def test_from_api_partial_data(self):
        # Data with only essential fields (like from TRASH_QUERY_FIELDS)
        data = {
            "id": "file123",
            "name": "test.txt",
            "size": "1024",
            "webViewLink": "https://example.com/view"
        }

        f = DriveFile.from_api(data)

        self.assertEqual(f.id, "file123")
        self.assertEqual(f.name, "test.txt")
        self.assertEqual(f.size, 1024)
        self.assertEqual(f.webViewLink, "https://example.com/view")

        # Check that missing fields are handled safely
        self.assertEqual(f.mimeType, "")
        self.assertIsNone(f.md5Checksum)
        self.assertFalse(f.trashed)
        self.assertEqual(f.owners, ())
        self.assertIsNone(f.createdTime)
        self.assertIsNone(f.modifiedTime)

    def test_from_api_missing_optional_fields(self):
        # Minimum possible data
        data = {"id": "id001"}
        f = DriveFile.from_api(data)
        self.assertEqual(f.id, "id001")
        self.assertEqual(f.name, "")
        self.assertIsNone(f.size)
        self.assertEqual(f.owners, ())

if __name__ == "__main__":
    unittest.main()
