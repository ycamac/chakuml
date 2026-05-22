/** @type {import('next').NextConfig} */
const nextConfig = {
  async rewrites() {
    return [
      {
        source: '/api/ml/:path*',
        destination: `${process.env.API_URL}/api/ml/:path*`,
      },
      {
        source: '/api/db/:path*',
        destination: `${process.env.API_URL}/api/db/:path*`,
      },
    ]
  },
}

module.exports = nextConfig
