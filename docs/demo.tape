# stop2shell — demo recording for VHS (https://github.com/charmbracelet/vhs)
# Run from the repository root: vhs docs/demo.tape

Output demo.gif

Set FontFamily "JetBrains Mono"
Set FontSize 16
Set Width 1100
Set Height 720
Set Padding 24
Set Theme "Catppuccin Mocha"
Set TypingSpeed 55ms

Type "./stop2shell.sh"
Enter
Sleep 3s

Type "id"
Enter
Sleep 700ms

Type "cat flag.txt"
Enter
Sleep 700ms

Type "ls -la"
Enter
Sleep 700ms

Type "sudo rm -rf /"
Enter
Sleep 900ms

Type "exit"
Enter
Sleep 900ms

Type "stop2shell"
Enter
Sleep 4s
