#!/usr/bin/env python

from numpy import arange
import matplotlib.pyplot as pp
import argparse

def f(rank, s, c):
	return c / (rank ** s)

def best_fit(freq):
	s_best, c_best, e_best = 1, 1, 10**10

	for c in xrange(5000, 20000, 200):
		for s in arange(0.2, 1, 0.2):
			e = sum([abs(f(rank+1, s, c) - freq[rank])**2 for rank in xrange(len(freq))]) / len(freq)
			if e < e_best:
				e_best, s_best, c_best = e, s,  c
	
	print("Best values: %f %d" % (s_best, c_best))
	return (s_best, c_best)

def plot_stuff(freq, s, c, output_path):
	end = len(freq)
	z = [f(i+1, s, c)  for i in xrange(0, end)]

	fig = pp.figure()
	ax = fig.add_subplot(1, 1, 1)
	
	x = xrange(0, end)
	ax.plot(x, freq[0:end], 'r--', label="Real frequency")
	ax.plot(x, z, '0.0', label="Zipf's law",)
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
	s, c = best_fit(freq)
	plot_stuff(freq, s, c, args.o)

if __name__ == '__main__':
	main()
