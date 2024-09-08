/**
 * Welcome to Cloudflare Workers! This is your first worker.
 *
 * - Run `npm run dev` in your terminal to start a development server
 * - Open a browser tab at http://localhost:8787/ to see your worker in action
 * - Run `npm run deploy` to publish your worker
 *
 * Learn more at https://developers.cloudflare.com/workers/
 */

/*
export default {
	async fetch(request, env, ctx) {
		return new Response('Hello World!');
	},
};
*/

var src_default = {
  async fetch(request, env, ctx) {
    // Retrieve the API key from the request headers
    const apiKey = request.headers.get('x-api-key');
    const validApiKey = 'my-secret-api-key-12345'; // Replace with your actual API key

    // Check if the API key is valid
    if (apiKey !== validApiKey) {
      return new Response('Unauthorized', { status: 401 });
    }

    // Handle POST request
    if (request.method === 'POST') {
      const data = await request.json();
      console.log(data);
      return new Response('Data received', { status: 200 });
    } else {
      return new Response('Only POST method is supported', { status: 405 });
    }
  }
};

export {
  src_default as default
};
