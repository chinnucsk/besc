.PHONY: clean deps compile dialyze plt

all: compile dialyze

clean:
	@script/rebar clean skip_deps=true

deps:
	@script/rebar get-deps

compile:
	@script/rebar compile skip_deps=true

dialyze:
	@dialyzer -r ebin --check_plt --quiet
	@dialyzer --quiet \
		--plts `find script/plts -name '*.plt'` \
		-Wunmatched_returns \
		-Werror_handling \
		-Wrace_conditions \
		-Wno_return \
		`find ebin -name '*.beam'`

plt:
	-@dialyzer -r ebin --build_plt --output_plt script/plts/__app.plt
	@script/gen_plt
