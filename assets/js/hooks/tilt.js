export const Tilt = {
  mounted() {
    this.el.addEventListener("mousemove", (e) => {
      const rect = this.el.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const centerX = rect.width / 2;
      const centerY = rect.height / 2;
      const rotateX = ((y - centerY) / centerY) * -8;
      const rotateY = ((x - centerX) / centerX) * 8;
      this.el.style.transform = `perspective(500px) rotateX(${rotateX}deg) rotateY(${rotateY}deg)`;
    });

    this.el.addEventListener("mouseleave", () => {
      this.el.style.transform = "perspective(500px) rotateX(0deg) rotateY(0deg)";
    });
  }
};
