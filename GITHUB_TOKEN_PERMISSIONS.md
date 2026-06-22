# GitHub Token Permissions for MCP Server

## Current Issue
The GitHub MCP server is configured but lacks permissions to add comments to issues. The error received was:
```
Permission Denied: Resource not accessible by personal access token
```

## Required Permissions

To enable full functionality including adding comments, the GitHub Personal Access Token (PAT) needs these scopes:

### Classic Personal Access Token Scopes
If using a classic token, enable these scopes:

1. **`repo`** (Full control of private repositories)
   - Includes: `repo:status`, `repo_deployment`, `public_repo`, `repo:invite`, `security_events`
   - **This is the main scope needed for issue comments**

2. **`write:discussion`** (Read and write team discussions)
   - Needed if working with GitHub Discussions

### Fine-Grained Personal Access Token Permissions
If using fine-grained tokens (recommended), set these permissions:

1. **Repository Permissions:**
   - **Issues**: Read and write
   - **Pull requests**: Read and write (if needed)
   - **Contents**: Read and write (for file operations)
   - **Metadata**: Read (automatically included)

2. **Organization Permissions** (if applicable):
   - None required for personal repos

## How to Update Token Permissions

### Option 1: Update Existing Token
1. Go to GitHub Settings: https://github.com/settings/tokens
2. Find your token (or create new one)
3. Click "Edit" or "Generate new token"
4. For **Classic Token**: Check the `repo` scope
5. For **Fine-Grained Token**: Set "Issues" to "Read and write"
6. Click "Update token" or "Generate token"
7. Copy the new token

### Option 2: Create New Token with Correct Permissions

#### Classic Token (Easier):
1. Go to: https://github.com/settings/tokens/new
2. Name: "Bob MCP Server - Full Access"
3. Expiration: Choose appropriate duration
4. Select scopes:
   - ✅ **repo** (Full control of private repositories)
   - ✅ **workflow** (if you need GitHub Actions)
5. Click "Generate token"
6. Copy token immediately (won't be shown again)

#### Fine-Grained Token (More Secure):
1. Go to: https://github.com/settings/personal-access-tokens/new
2. Token name: "Bob MCP Server"
3. Expiration: Choose duration
4. Repository access: 
   - Select "Only select repositories"
   - Choose: `msrikanthkan/travelbuddyai`
5. Repository permissions:
   - **Issues**: Read and write ✅
   - **Contents**: Read and write ✅
   - **Pull requests**: Read and write (optional)
   - **Metadata**: Read (auto-selected)
6. Click "Generate token"
7. Copy token

## Update MCP Server Configuration

After getting the new token, update your MCP configuration:

### Location
The GitHub MCP server configuration is typically in:
- Windows: `%APPDATA%\Code\User\globalStorage\rooveterinaryinc.roo-cline\settings\cline_mcp_settings.json`
- Or in VS Code settings

### Update Token
Find the GitHub MCP server configuration and update the token:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_NEW_TOKEN_HERE"
      }
    }
  }
}
```

### Restart Required
After updating:
1. Restart VS Code or Bob
2. Test with a simple comment operation

## Testing Token Permissions

Test if the token works by trying to add a comment:

```bash
# Using curl to test
curl -X POST \
  -H "Authorization: token YOUR_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/msrikanthkan/travelbuddyai/issues/6/comments \
  -d '{"body":"Test comment from API"}'
```

If successful, you'll get a 201 response with the comment data.

## Security Best Practices

1. **Use Fine-Grained Tokens** when possible (more secure)
2. **Limit Repository Access** to only repos you need
3. **Set Expiration** - tokens should expire (30-90 days recommended)
4. **Rotate Regularly** - update tokens periodically
5. **Never Commit Tokens** - keep them in environment variables or secure config
6. **Revoke Unused Tokens** - clean up old tokens

## Current Workaround

Until token permissions are updated, use these alternatives:

1. **Manual Updates**: Update GitHub issues via web interface
2. **Git Commits**: Document progress in commit messages
3. **Status Document**: Use `ROAD_TRIP_IMPLEMENTATION_STATUS.md` for tracking
4. **GitHub CLI**: Use `gh` command if installed:
   ```bash
   gh issue comment 6 --body "Your comment here"
   ```

## Summary

**Minimum Required Scope**: `repo` (for classic tokens) or "Issues: Read and write" (for fine-grained tokens)

**Current Status**: Token has read access but not write access for issues

**Action Needed**: Update token with `repo` scope or "Issues: Read and write" permission

---

**Document Version:** 1.0  
**Last Updated:** 2026-06-17