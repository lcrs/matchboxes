# This writes out the second set of flooding passes from a template
template = open('Ls_Poly.15.glsl').readlines()

for p in range(16, 27):
	r = p - 14
	d = pow(2, 12-r)
	f = 'Ls_Poly.%d.glsl' % p
	print f
	t = list(template)

	t[1] = "// Pass %d: jump flood out addresses of closest seeds, round %d, distance %d\n" % (p, r, d)
	t[5] = "uniform sampler2D adsk_results_pass%d;\n" % (p - 1)
	t[45] = "      vec4 seeds = texture2D(adsk_results_pass%d, xy + vec2(j, k) * (vec2(%d.0)/res));\n" % (p - 1, d)
	print t[1] + t[5] + t[45]

	open(f, 'w').write('' .join(t))
