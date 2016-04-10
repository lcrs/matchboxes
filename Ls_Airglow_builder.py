#!/usr/bin/python

for blur in range(1, 9):
    # Write horizontal pass
    filename = 'Ls_Airglow.%02d.glsl' % (blur * 2)
    print filename

    # Write vertical pass
    filename = 'Ls_Airglow.%02d.glsl' % (blur * 2 + 1)
    print filename
