# TravelBuddyAI Documentation Update Helper Script
# Run this script whenever you make changes to the application

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📚 TravelBuddyAI Documentation Helper" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if git is available
function Test-GitAvailable {
    try {
        git --version | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Check for recent changes
if (Test-GitAvailable) {
    Write-Host "🔍 Analyzing recent changes..." -ForegroundColor Yellow
    Write-Host ""
    
    # Get changed files (staged and unstaged)
    $stagedFiles = git diff --cached --name-only 2>$null
    $unstagedFiles = git diff --name-only 2>$null
    $allChangedFiles = @($stagedFiles) + @($unstagedFiles) | Select-Object -Unique
    
    if ($allChangedFiles.Count -gt 0) {
        Write-Host "📝 Recently modified files:" -ForegroundColor Green
        $allChangedFiles | ForEach-Object { 
            if ($_ -ne "") {
                Write-Host "   • $_" -ForegroundColor White
            }
        }
        Write-Host ""
    }
    else {
        Write-Host "ℹ️  No uncommitted changes detected" -ForegroundColor Gray
        Write-Host ""
    }
}
else {
    Write-Host "ℹ️  Git not available - skipping change detection" -ForegroundColor Gray
    Write-Host ""
}

# Analyze which sections need updates
Write-Host "📋 Documentation sections that may need updates:" -ForegroundColor Cyan
Write-Host ""

$sectionsToUpdate = @()

# Check models
if ($allChangedFiles -match "lib/models/") {
    Write-Host "   ✓ Section 5: Data Models" -ForegroundColor Yellow
    $sectionsToUpdate += "Data Models"
}

# Check services
if ($allChangedFiles -match "lib/services/") {
    Write-Host "   ✓ Section 6: Services & APIs" -ForegroundColor Yellow
    $sectionsToUpdate += "Services & APIs"
}

# Check screens
if ($allChangedFiles -match "lib/screens/") {
    Write-Host "   ✓ Section 3: Core Features" -ForegroundColor Yellow
    Write-Host "   ✓ Section 7: User Interface" -ForegroundColor Yellow
    $sectionsToUpdate += "Core Features"
    $sectionsToUpdate += "User Interface"
}

# Check dependencies
if ($allChangedFiles -match "pubspec.yaml") {
    Write-Host "   ✓ Section 9.2: Dependencies" -ForegroundColor Yellow
    $sectionsToUpdate += "Dependencies"
}

# Check Firebase
if ($allChangedFiles -match "firebase") {
    Write-Host "   ✓ Section 8: Firebase Integration" -ForegroundColor Yellow
    $sectionsToUpdate += "Firebase Integration"
}

# Check architecture
if ($allChangedFiles -match "lib/main.dart") {
    Write-Host "   ✓ Section 4: Technical Architecture" -ForegroundColor Yellow
    $sectionsToUpdate += "Technical Architecture"
}

if ($sectionsToUpdate.Count -eq 0) {
    Write-Host "   ✓ No critical sections detected" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Offer to open documentation
Write-Host "Would you like to:" -ForegroundColor White
Write-Host "  [1] Open documentation in browser" -ForegroundColor White
Write-Host "  [2] Open documentation in VS Code" -ForegroundColor White
Write-Host "  [3] Open maintenance guide" -ForegroundColor White
Write-Host "  [4] Exit" -ForegroundColor White
Write-Host ""
Write-Host "Enter your choice (1-4): " -NoNewline -ForegroundColor Cyan

$choice = Read-Host

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "🌐 Opening documentation in browser..." -ForegroundColor Green
        Start-Process "TravelBuddyAI_Documentation.html"
    }
    "2" {
        Write-Host ""
        Write-Host "📝 Opening documentation in VS Code..." -ForegroundColor Green
        code "TravelBuddyAI_Documentation.html"
    }
    "3" {
        Write-Host ""
        Write-Host "📖 Opening maintenance guide..." -ForegroundColor Green
        code "DOCUMENTATION_MAINTENANCE.md"
    }
    "4" {
        Write-Host ""
        Write-Host "👋 Goodbye!" -ForegroundColor Cyan
    }
    default {
        Write-Host ""
        Write-Host "❌ Invalid choice. Exiting..." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "💡 Tip: Run this script before committing changes!" -ForegroundColor Yellow
Write-Host ""

# Made with Bob
