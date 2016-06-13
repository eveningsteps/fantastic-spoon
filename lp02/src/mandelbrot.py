#!/usr/bin/env python

import sys
from numpy import arange
import matplotlib.pyplot as pp
import argparse

from functools import partial
from multiprocessing.pool import Pool

def f(rank, P, rho, B):
	return P * ((rank + rho) ** (-B))

def best_fit(freq, p):
	p_best, rho_best, b_best, e_best = p, 1, 1, 10**10
	
	for rho in arange(0.5, 2, 0.25):
		for b in arange(0.7, 1.5, 0.1):
			e = sum([abs(f(rank+1, p, rho, b) - freq[rank])**2 for rank in xrange(len(freq))]) / len(freq)
			if e < e_best:
				p_best, rho_best, b_best, e_best = p, rho, b, e

	return (e_best, p_best, rho_best, b_best)

def plot_stuff(freq, p, rho, b, output_path):
	end = min(10**3, len(freq))
	z = [f(i+1, p, rho, b)  for i in xrange(0, end)]

	fig = pp.figure()
	ax = fig.add_subplot(1, 1, 1)
	
	x = xrange(0, end)
	ax.plot(x, freq[0:end], 'r--', label="Real frequency")
	ax.plot(x, z, '0.0', label="Zipf-Mandelbrot's law")
	ax.set_yscale("log")
	ax.set_xscale("log")

	pp.legend()
	pp.xlabel("rank")
	pp.ylabel("frequency")
	pp.savefig(output_path)

def parse_args():
 	parser = argparse.ArgumentParser(description = 'Find best parameters for Zipf\'s law')
	parser.add_argument('-i', help='path to dictionary', required=True)
	parser.add_argument('-o', help='path to output image', required=True)
	parser.add_argument('-t', type=int, default=4, help='no. of coprocesses')
	return parser.parse_args()

def main():
	args = parse_args()
	f = open(args.i, "r")
	n = int(f.readline())

	freq = []
	for l in f:
		_, fr, _ = l.split()
		freq.append(int(fr))
	
	freq.sort(reverse=True)
	bf = partial(best_fit, freq)

	p = Pool(args.t)
	res = p.map(bf, arange(1 * 10**4, 5 * 10**4, 1000))
	res.sort(key=lambda x: x[0])
	e, p, rho, b = res[0]

	print("Best values: %d %f %f (error: %f)" % (p, rho, b, e))
	plot_stuff(freq, p, rho, b, args.o)

if __name__ == '__main__':
	main()

