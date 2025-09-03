# Add TypedStream Failure Test Case

**Description**: Extract raw TypedStream data from chat.db for a failing message ID and create a test case to debug and fix the parsing issue.

**Usage**:

```bash
/add-typestream-failure <message_id>
```

**Example**:

```bash
/add-typestream-failure 155197
```

**What it does**:
1. Asks for screenshots of the original iMessage and the failing decoded message
2. Extracts raw TypedStream data from chat.db for the given message ID
3. Adds a new failing test case to `test/typedstream/test_extracted_real_data.rb`
4. Runs the test to confirm it fails
5. Analyzes the failure and attempts to fix the TypedStream parser
6. Re-runs the test to validate the fix

**Prerequisites**:
- Full Disk Access enabled for Terminal/IDE to read ~/Library/Messages/chat.db
- Valid message ID that exists in the database
- Screenshots showing the parsing issue

**Process**:
- Interactive prompts for screenshots and expected content
- Automatic raw data extraction and hex analysis
- Test case generation with proper assertions
- Automated debugging and parser improvements
- Validation of fixes with full test suite
