<#
- Given an existing repository with  submodules, merge the submodule repos into the parent repo (1 level deepth, not recursive).
- Set the path to the root of the repo.
- The script creates a branch for each submodule like 'merge/submodulename", you can delete these branches, if you don't it's fine, they dont get pushed anyway.
- Notice that merging repos doesn't bring all the branches, you will have to checkout all branches that you want from the sub-repos and push them to the main repo if you don't want to lose them!
- After finishing, you may remove the "remotes" added after you move the branches you want.
- You may also want to remove .gitignore files from the old submodule's folders.
#>

# OPTIONAL INITIALIZATION: (not necessary if you already cloned the repo)
$gitRepo = "https://myServer.com/myRepo.git"
git clone $gitRepo # --recursive
cd ([System.IO.Path]::GetFileName($gitRepo) -replace ".git$", "")


# EXECUTION:
$subModuleLinesRaw = git submodule
$subModuleList = @()
foreach ($subModuleLine in $subModuleLinesRaw)
{
  $subModuleLineParts = $subModuleLine.Trim("-").Trim(" ") -split " "
  $subModuleList += [PSCustomObject]@{
    Commit = $subModuleLineParts[0]
    Name = $subModuleLineParts[1]
    Branches = $subModuleLineParts[2]
    Url = ""
  }
}
if ($subModuleList.Count -eq 0) {
  Write-Host "No submodules to merge!" -ForegroundColor Yellow
} else {
  Write-Host "Merging repository submodules: $($subModuleList.Count) submodules found" -ForegroundColor Magenta
}
# Get the submodule's git url:
# (Another option would be to read the file ".gitmodules" and parsing it)
# git config --file .gitmodules --get-regexp url
git submodule update --init  # Ensure submodules are cloned to get their url
foreach ($subModule in $subModuleList)
{
  $rootDir = $pwd
  cd $subModule.Name
  $subModule.Url = git config --get remote.origin.url
  cd $rootDir
  # All submodules must be deinit to prevent conflicts when checking out submodule's branches.
  git submodule deinit $subModule.Name
}
foreach ($subModule in $subModuleList)
{
  # $subModule = $subModuleList[0]
  Write-Host "Merging SubModule:  $subModule" -ForegroundColor Magenta
  
  git remote add -f "$($subModule.Name)" $subModule.Url
  
  # Move submodule content to folder:
  #git checkout "$($subModule.Name)/master"
  git checkout $subModule.Commit
  $subModuleBranch = "merge/$($subModule.Name)"
  git checkout -b $subModuleBranch
  $subModuleFolderName = "$($subModule.Name)_folder-$(New-Guid)"
  mkdir $subModuleFolderName
  dir -Exclude $subModuleFolderName | %{ git mv $_.Name $subModuleFolderName }
  git mv $subModuleFolderName $subModule.Name
  git commit -m "Move submodule '$($subModule.Name)' to folder to merge repos."
  
  # Remove submodule and merge:
  git checkout master
  git submodule deinit $subModule.Name
  git rm $subModule.Name
  git commit -m "Removed submodule '$($subModule.Name)"
  
  git merge --allow-unrelated-histories  $subModuleBranch
  git commit -m "Move repo '$repoName' files into subdir."
}
Write-Host "Finished Merging SubModules." -ForegroundColor Green
