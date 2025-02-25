from cube import TemplateContext

template = TemplateContext()

tenant_id_claim = 'https://synccomputing.com/sync_tenant_id'
tenant_id_override_claim = 'https://synccomputing.com/sync_tenant_id_override'

@template.function('tenant_resolver')
def tenant_resolver(ctx) -> str:
    if ctx is None:
        raise Exception("You shall not pass! 🧙")

    sync_tenant_id = (
        ctx.get(tenant_id_override_claim) 
        or ctx.get(tenant_id_claim)
    )
    
    if sync_tenant_id is None:
        raise Exception("You shall not pass! 🧙")
    return sync_tenant_id