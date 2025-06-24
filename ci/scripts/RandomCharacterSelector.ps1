# Define the list of Classes
$gameData = @{
    "Alliance" = @{
        "Human"     = @("Warrior", "Paladin", "Rogue", "Priest", "Warlock", "Mage")
        "Dwarf"     = @("Warrior", "Paladin", "Rogue", "Priest")
        "Night Elf" = @("Warrior", "Rogue", "Priest", "Hunter", "Druid")
        "Gnome"     = @("Warrior", "Rogue", "Priest", "Warlock", "Mage")

    }
    "Horde" = @{
        "Orc"       = @("Warrior", "Rogue", "Shaman", "Warlock", "Hunter")
        "Undead"    = @("Warrior", "Rogue", "Priest", "Warlock", "Mage")
        "Tauren"    = @("Warrior", "Hunter", "Druid", "Shaman")
        "Troll"     = @("Warrior", "Rogue", "Priest", "Hunter", "Mage", "Shaman")
    }
}

# Define specialisations for each class
$specalisations = @{
    "Warrior" = @("Arms", "Fury", "Protection")
    "Paladin" = @("Holy", "Protection", "Retribution")
    "Hunter"  = @("Beast Mastery", "Marksmanship", "Survival")
    "Rogue"   = @("Assassination", "Combat", "Subtlety")
    "Priest"  = @("Discipline", "Holy", "Shadow")
    "Shaman"  = @("Elemental", "Enhancement", "Restoration")
    "Mage"    = @("Arcane", "Fire", "Frost")
    "Warlock" = @("Affliction", "Demonology", "Destruction")
    "Druid"   = @("Balance", "Feral", "Restoration")
}

# Define body types
$bodyTypes = @("Body Type 1 (Male)", "Body Type 2 (Female)")

# Define class colors
$classColors = @{
    "Warrior" = "DarkYellow"
    "Paladin" = "Magenta"
    "Hunter"  = "Green"
    "Rogue"   = "Yellow"
    "Priest"  = "White"
    "Shaman"  = "Blue"
    "Mage"    = "Cyan"
    "Warlock" = "DarkCyan"
    "Druid"   = "Orange"
}

# Define faction colors
$factionColors = @{
    "Alliance" = "Blue"
    "Horde"    = "Red"
}

# Function to randomly select a specalisation based on the class
function Get-RandomSpec {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Class
    )
    $specalisations[$Class] | Get-Random
}

# Function to randomly select an item from a list
function Get-RandomItem {
    param (
        [Parameter(Mandatory=$true)]
        [array]$List
    )
    $List | Get-Random
}

# Select a random faction
$randomFaction = Get-RandomItem -List $gameData.Keys

# Select a random race based on the faction
$randomRace = Get-RandomItem -List ($gameData[$randomFaction].Keys)

# Select a random class based on the selected race
$randomClass = Get-RandomItem -List ($gameData[$randomFaction][$randomRace])

# Select a random body type
$randomBodyType = Get-RandomItem -List $bodyTypes

# Select a random specalisation based on the selected class
$randomSpec = Get-RandomSpec -Class $randomClass

# Output the results with color
Write-Host "Your randomly selected faction is: $randomFaction" -ForegroundColor $factionColors[$randomFaction]
Write-Host "Your randomly selected race is: $randomRace"
Write-Host "Your randomly selected class is: $randomClass" -ForegroundColor $classColors[$randomClass]
Write-Host "Your randomly selected body type is: $randomBodyType"
Write-Host "Your randomly selected specalisation is: $randomSpec"
