<#
- Given an empty folder, this scripts creates a new repo and then adds all repos to merge as remotes, then merges all together.
- Set the path to an empty folder.
#>

# CONFIG:
$gitReposToMerge = @(
  @{  Name = "MyRepo1";    IsRoot = $true;   Url = "https://myServer.com/myRepo1.git"    }
  @{  Name = "MyRepo2";    IsRoot = $true;   Url = "https://myServer.com/myRepo2.git"    }
  @{  Name = "MyRepoBase"; IsRoot = $false;  Url = "https://myServer.com/myRepoBase.git" }
)


# EXECUTION:
git init
git commit --allow-empty -m "Initial commit required to merge repos."
$FoldersToExclude = @()

$gitReposToMerge = $gitReposToMerge | Sort-Object -Property IsRoot  #root repos must appear LAST.
foreach ($repo in $gitReposToMerge)
{
  # $repo = $gitReposToMerge[0]
  $repoUrl = $repo.Url
  $repoName = $repo.Name
  
  # Uses an unique folder name to move all repo files so that files from other repos doesn't overwrite the previous ones.
  $repoFolderName = "$($repoName)-folder-$(New-Guid)"
  
  git remote add -f "$repoName" "$repoUrl"
  git merge --allow-unrelated-histories  "$repoName/master"
  
  if ($repo.IsRoot) {
    continue
  }
  # The rest of the steps are optional. It moves all files to a sub-folder with the repo name:
  mkdir "$repoFolderName"
  $FoldersToExclude += "$repoFolderName"
  dir -exclude $FoldersToExclude | %{git mv $_.Name "$repoFolderName"}
  git commit -m "Move repo '$repoName' files into subdir."
}

foreach ($subRepoFolder in $FoldersToExclude)
{
  $repoName = $subRepoFolder -replace "-folder.*?$", ""
  git mv "$subRepoFolder" "$repoName"
}
git commit -m "Rename repo subdir folders"
