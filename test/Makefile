check:
	@allok=:; \
	  for f in *.sh; do echo "test: $$f"; sh $$f || { allok=false; }; done; \
	  if $$allok; then echo ALL GOOD; else echo "SOME TESTS FAILED"; fi
