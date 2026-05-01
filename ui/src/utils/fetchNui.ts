export async function fetchNui<T = any>(eventName: string, data?: any): Promise<T> {
  const options = {
    method: 'post',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify(data),
  };

  const resourceName = (window as any).GetParentResourceName ? (window as any).GetParentResourceName() : 'mri_Qpets';

  try {
    const resp = await fetch(`https://${resourceName}/${eventName}`, options);
    const text = await resp.text();
    
    // Safely parse JSON or return the raw text/empty object
    try {
      return (text ? JSON.parse(text) : {}) as T;
    } catch {
      return text as any;
    }
  } catch (error) {
    console.error(`[fetchNui] Error fetching ${eventName}:`, error);
    return {} as T;
  }
}
