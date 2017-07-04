# This writes out the first set of flooding passes from a template
template = open('Ls_Poly.02.glsl').readlines()

for p in range(3, 15):
	r = p - 1
	d = pow(2, 13-r)
	f = 'Ls_Poly.%02d.glsl' % p
	print f
	t = list(template)

	t[1] = "// Pass %d: jump flood out coords of closest seeds, round %d, distance %d\n" % (p, r, d)
	t[4] = "uniform sampler2D adsk_results_pass%d;\n" % (p - 1)
	t[19] = "      vec4 s = texture2D(adsk_results_pass%d, xy + vec2(j, k) * (vec2(%d.0)/res));\n" % (p - 1, d)
	print t[1] + t[4] + t[19]

	open(f, 'w').write('' .join(t))


# The second set of flooding passes
template = open('Ls_Poly.16.glsl').readlines()

for p in range(17, 29):
	r = p - 15
	d = pow(2, 13-r)
	f = 'Ls_Poly.%d.glsl' % p
	print f
	t = list(template)

	t[1] = "// Pass %d: jump flood out addresses of closest seeds, round %d, distance %d\n" % (p, r, d)
	t[5] = "uniform sampler2D adsk_results_pass%d;\n" % (p - 1)
	t[45] = "      vec4 seeds = texture2D(adsk_results_pass%d, xy + vec2(j, k) * (vec2(%d.0)/res));\n" % (p - 1, d)
	print t[1] + t[5] + t[45]

	open(f, 'w').write('' .join(t))
