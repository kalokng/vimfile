curl.exe -fLo %LOCALAPPDATA%/nvim-data/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim 
mklink /j %homedrive%%homepath%\AppData\Local\nvim %~dp0\nvim
