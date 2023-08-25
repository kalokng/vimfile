curl.exe -fLo %homedrive%%homepath%/vimfiles/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim 
mklink %homedrive%%homepath%\_vimrc %~dp0\_vimrc
mklink %homedrive%%homepath%\_gvimrc %~dp0\_gvimrc
