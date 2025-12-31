# Deploying BTC3 Website to GoDaddy

This guide will help you deploy your BTC3 website to your GoDaddy domain.

## Option 1: GoDaddy Website Builder / Hosting (Recommended for Beginners)

### Step 1: Access Your GoDaddy Hosting

1. Log in to [GoDaddy.com](https://www.godaddy.com)
2. Go to **My Products**
3. Find your domain and click **Manage**

### Step 2: Set Up Hosting

If you don't have hosting yet:
1. Click **Get Started** next to your domain
2. Choose **Web Hosting** (cheapest option is fine)
3. Complete the purchase

If you already have hosting:
1. Go to **Web Hosting** in your products
2. Click **Manage**

### Step 3: Upload Your Website Files

**Using File Manager:**

1. In your hosting control panel, click **cPanel** or **File Manager**
2. Navigate to `public_html` folder (this is your website root)
3. Delete any default files (like `index.html` or `coming-soon.html`)
4. Click **Upload** button
5. Upload these files from your `website` folder:
   - `index.html`
   - `style.css`
   - `script.js`

**Using FTP (Alternative):**

1. In GoDaddy hosting, find your **FTP credentials**
2. Download an FTP client like [FileZilla](https://filezilla-project.org/)
3. Connect using your FTP credentials
4. Navigate to `public_html` folder
5. Upload your website files

### Step 4: Update Links in Your Website

Before uploading, update `index.html`:

**Find and replace:**
- `cgebitcoin` → Your actual GitHub organization/username
- `YOUR-HANDLE` → Your actual Twitter handle
- `https://discord.gg/ShhRfE9D` → Your actual Discord invite link

### Step 5: Test Your Website

1. Open your domain in a browser (e.g., `https://yourdomain.com`)
2. Check that everything loads correctly
3. Test all links and buttons

---

## Option 2: GitHub Pages + GoDaddy Domain (Free Hosting, Recommended)

This option is **FREE** and easier to maintain!

### Step 1: Push Website to GitHub

```bash
cd /Users/gurkanerdogdu/tmp/btc5

# Add website files to git
git add website/
git commit -m "Add BTC3 website"
git push origin main
```

### Step 2: Enable GitHub Pages

1. Go to your GitHub repository
2. Click **Settings**
3. Scroll to **Pages** (left sidebar)
4. Under **Source**, select:
   - Branch: `main`
   - Folder: `/website`
5. Click **Save**
6. Wait 1-2 minutes, your site will be live at `https://cgebitcoin.github.io/btc3/`

### Step 3: Connect Your GoDaddy Domain to GitHub Pages

**In GoDaddy:**

1. Log in to GoDaddy
2. Go to **My Products** → **Domains**
3. Click **DNS** next to your domain
4. Click **Add** to add new records
5. Add these DNS records:

   **Record 1 (A Record):**
   - Type: `A`
   - Name: `@`
   - Value: `185.199.108.153`
   - TTL: `600`

   **Record 2 (A Record):**
   - Type: `A`
   - Name: `@`
   - Value: `185.199.109.153`
   - TTL: `600`

   **Record 3 (A Record):**
   - Type: `A`
   - Name: `@`
   - Value: `185.199.110.153`
   - TTL: `600`

   **Record 4 (A Record):**
   - Type: `A`
   - Name: `@`
   - Value: `185.199.111.153`
   - TTL: `600`

   **Record 5 (CNAME for www):**
   - Type: `CNAME`
   - Name: `www`
   - Value: `cgebitcoin.github.io`
   - TTL: `600`

6. **Delete** any existing `A` records pointing to GoDaddy parking page
7. Click **Save**

**In GitHub:**

1. Go back to your repo **Settings** → **Pages**
2. Under **Custom domain**, enter your domain (e.g., `btc3.com`)
3. Click **Save**
4. Wait for DNS check to complete
5. Enable **Enforce HTTPS** (recommended)

### Step 4: Wait for DNS Propagation

- DNS changes can take 1-48 hours (usually 1-2 hours)
- Check status at [whatsmydns.net](https://www.whatsmydns.net)
- Your website will be live at `https://yourdomain.com`

---

## Option 3: Netlify + GoDaddy Domain (Free, Fastest)

### Step 1: Deploy to Netlify

1. Go to [Netlify.com](https://www.netlify.com)
2. Sign up with GitHub
3. Click **Add new site** → **Import an existing project**
4. Choose GitHub and select your `btc3` repository
5. Set:
   - Base directory: `website`
   - Build command: (leave empty)
   - Publish directory: `.`
6. Click **Deploy**

Your site will be live at `https://random-name.netlify.app`

### Step 2: Add Custom Domain

**In Netlify:**

1. Go to **Site settings** → **Domain management**
2. Click **Add custom domain**
3. Enter your domain (e.g., `btc3.com`)
4. Netlify will show you DNS records to add

**In GoDaddy:**

1. Go to **My Products** → **Domains** → **DNS**
2. Add the DNS records Netlify provided (usually CNAME or A records)
3. Save

### Step 3: Enable HTTPS

1. In Netlify, go to **Domain settings**
2. Click **Verify DNS configuration**
3. Once verified, click **Provision certificate**
4. HTTPS will be enabled automatically

---

## Quick Comparison

| Option | Cost | Difficulty | Speed | Best For |
|--------|------|------------|-------|----------|
| **GoDaddy Hosting** | $5-10/month | Easy | Medium | If you already have hosting |
| **GitHub Pages** | FREE | Medium | Fast | Best value, easy updates |
| **Netlify** | FREE | Easy | Fastest | Easiest setup, best performance |

---

## Recommended: GitHub Pages or Netlify

**Why?**
- ✅ **FREE** forever
- ✅ **Automatic HTTPS**
- ✅ **Fast CDN** (content delivery network)
- ✅ **Easy updates** (just push to GitHub)
- ✅ **No server maintenance**

**GoDaddy hosting is only needed if:**
- You want email hosting on the same domain
- You need server-side features (PHP, databases)
- You already paid for it

---

## After Deployment Checklist

- [ ] Website loads at your domain
- [ ] All links work (GitHub, Twitter, etc.)
- [ ] HTTPS is enabled (green padlock)
- [ ] Mobile version looks good
- [ ] All sections display correctly
- [ ] Code blocks are copyable

---

## Troubleshooting

### "Site not found" or "404 error"
- Wait for DNS propagation (up to 48 hours)
- Check DNS records are correct
- Clear browser cache

### "Not Secure" warning
- Wait for SSL certificate to provision (can take 24 hours)
- Make sure HTTPS is enabled in hosting settings

### Links don't work
- Update `YOUR-USERNAME` and `YOUR-HANDLE` in `index.html`
- Make sure you pushed changes to GitHub

### Website looks broken
- Check that all 3 files are uploaded: `index.html`, `style.css`, `script.js`
- Check browser console for errors (F12)

---

## Need Help?

If you run into issues:
1. Check GoDaddy's [help center](https://www.godaddy.com/help)
2. For GitHub Pages: [GitHub Pages docs](https://docs.github.com/en/pages)
3. For Netlify: [Netlify docs](https://docs.netlify.com)

---

**My recommendation: Use GitHub Pages (Option 2) - it's free, fast, and professional!**
