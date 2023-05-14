# bufmax.nvim -- Ensure maximum number of listed buffers

:warning: experimental

Simple plugin to make a max number of listed buffers.

It keeps track of the buffers you enter and tries to remove (`bdelete`) the ones you entered the longest ago.
Any buffer which is edited or not hidden is skipped.
