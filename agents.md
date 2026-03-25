Please write clean code and think about the repercussions of every implementation

for example

"Will this be supportable long term?"

"Is this extremely hard to test?"

"Is this the most efficient and clean way to do this?"

After every implementation, go back and clean up dead code, update readme with up to date project information, If you think whatever you implemented should be tested please test it.

Only write smart tests that are actually useful.

Whenever applicable, break implementations down into simpler parts, and divide the work amongst subagents.

Make the problem feedback-loopable for yourself as you work. Do not rely only on the interactive SDL window to judge correctness.

Build a small playground or debugging harness around the simulation so that the behavior is easy to inspect and easy to validate.

Set up reproducible experiments for tricky cases. If you find or suspect a bug, create a deterministic way to replay that exact scenario again instead of relying on manual timing or luck. Seed randomness where needed, and make initial conditions configurable.

the design requirements/philosophy can be found in gem_factory_design.md

Please update current_state.md with the current state of the project after every implementation