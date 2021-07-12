<!--Heya! Thanks for the PR. Please fill out this short little form below to help us review this faster-->

## Description
<!-- Any general story time goes here :) Feel free to add screenshots/recording of your change in action here-->

## Fixes issues: 
- Issue #nr...
- Un-tracked issue...

## Proposed Changes:
- Changed xyz...

## Change Categories
<!-- DELETE WHICHEVER BULLET DOES NOT APPLY -->
- Bug fix <!-- non-breaking change which fixes an issue -->
- New feature <!-- non-breaking change which adds functionality -->
- Breaking change <!-- fix or feature that would cause existing functionality to not work as expected -->
- Change in `functions` <!-- e.g. `utils`, `os`, `apt`, `ask`, etc. -->
- Project structure <!-- major rewrites, large directory changes, etc. -->
- Contribution flow <!-- IDE changes, `.github` dir, etc. -->

## Checklist
<!-- Please note that we also require you to check the CONTRIBUTORS.md file, this is just a short list-->
- [ ] Branch was made off the `develop` branch and the PR is targetting the `develop` branch
- [ ] Docs have been made OR are not necessary
    - PR link: 
- [ ] Changes to panel have been made OR are not necessary
    - PR link: 
- [ ] Code is formatted [(See more)](https://github.com/swizzin/swizzin/blob/master/CONTRIBUTING.md#editor-plugins-and-tooling)
- [ ] Code conforms to project structure [(See more)](https://swizzin.ltd/dev/structure)
- [ ] Shellcheck isn't screaming [(See more)](https://github.com/swizzin/swizzin/blob/master/CONTRIBUTING.md#editor-plugins-and-tooling)
- [ ] Prints to terminal are handled [(See more)](https://github.com/swizzin/swizzin/blob/master/CONTRIBUTING.md#printing-into-the-terminal)
- [ ] Changes have been made or are not necessary in `scripts/sysinfo` [(See nore)](https://github.com/swizzin/swizzin/blob/master/CONTRIBUTING.md#sysinfo-support)

- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] Testing was done
   - [ ] Tests created or no new tests necessary
   - [ ] Tests executed

## Test scenarios
<!-- Please let us know what has been done or anything else that works/doesn't. Feel free to copy-paste the examples at the bottom of this section -->

### Architectures
<!--
Please use these emojis here to fill the table below. It will nicely auto-format with spacing, don't worry. Leave empty wherever you do not know / have not tested
✅ = Works successfully
❎ = Does not work BUT is handled gracefully
🛠 = Still WIP
❌ = Broken / not working
-->
|   			| `amd64` 	| `armhf` 	| `arm64` 	| Unspecified 	|
|--------		|-------- 	|-------- 	|-------- 	|----------		|
| Focal 		|			|			|			|				|
| Bionic		|			|			|			|				|
| Buster		|			|			|			|				|
| Stretch		|			|			|			|				|
| Raspbian  	|	⚫️		|			|	⚫️		|	⚫️			|

### ✅❎ Passed

### 🛠🛠 TODO

### ❌❌ Currently failing

<!-- EXAMPLES :
- Fresh app install without nginx
    - With only one user
    - With multiple users present
- Fresh Install with nginx present nginx
    - With only one user
    - With multiple users present
- Fresh install and nginx install afterwards
    - With only one user
    - With multiple users present
- Update from version in master
- Upgrade from version in master
- Password gets changed from `box` in app
- User removal from `box` acting on app
- New user in `box` gets added to app
- Sysinfo compatibility
    - Info washed
    - Content available
-->

