# Container Security 101 Lab

## Getting Started

Run the lab setup container, and you should be good to go!

```bash
docker run --network host -v /:/host jonzeolla/labs:policy-as-code
```

## Customizing

If you need to pass custom arguments to the `ansible-playbook` command in the `entrypoint.sh`, pass in the arguments as an env var named `ANSIBLE_CUSTOM_ARGS`.

You can also specify a custom user by setting the `HOST_USER` environment variable inside the container.

## Updating

Standard updates are automated to run twice a week and open a PR if anything changes (via `task update`).
