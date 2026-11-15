import { redirect } from '@sveltejs/kit';

// El acceso está en la portada. Se mantiene para enlaces viejos.
export const load = () => redirect(308, '/');
